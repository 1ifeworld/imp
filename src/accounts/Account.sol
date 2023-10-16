// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {UserOperation} from "account-abstraction/interfaces/UserOperation.sol";
import {UserOperationLib} from "account-abstraction/interfaces/UserOperation.sol";

import {TokenCallbackHandler} from "./utils/TokenCallbackHandler.sol";

/*
    Things to consider adding

    - protected upgrade path, can only upgrade to impls registered by trusted operator
    - mutable _entrypoint address? look into likelihood entry point address changes in future
    - move events + errors + storage into seperate file
    - more restrictions on on what can be executed?
        - registered targets?
        - registered selectors?
    - some way to allow for different types of signing mechanisms to be allowed overtime in 
        _validateSignature() function?
*/

/*
    can potentially change back to just `Account`, because in the test suite you could hardcode
    in the import of `Account` test construct as `Account as AccountHelper` 
*/

/**
  * Based on ethinfitism `SimpleAccount.sol` implementation
  */
contract Account is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32; // hash.recover
    using MessageHashUtils for bytes32; // hash.toEthSignedMessageHash

    IEntryPoint private immutable _entryPoint;

    // NOTE: could potentially inherit the oz access level impl
    // NOTE: without an ddition
    mapping(address => uint256) public accessLevel;    

    event AccountInitialized(IEntryPoint indexed entryPoint, address indexed admin, address indexed delegate);
    event AdminAdded(address indexed sender, address indexed admin);
    event ApprovalAdded(address indexed sender, address indexed target);
    event ApprovalRemoved(address indexed sender, address indexed target);

    error Only_Admin();
    error OnlyAdmin_Or_Entrypoint();
    error Mismatched_Array_Lengths();

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }


    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    // NOTE: could potentially change the require to check if access > 1
    function _onlyAdmin() internal view {
        // directly from admin, or through the account itself (which gets redirected through execute())
        if (accessLevel[msg.sender] != 2 && msg.sender != address(this)) revert Only_Admin();
    }

    /**
     * execute a transaction (called directly from admin, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrAdmin();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        _requireFromEntryPointOrAdmin();
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "wrong array lengths");
        // note: test for gas efficiency and consider replacing require with this if + custom revert
        // if (dest.length != func.length || (value.length != 0 && value.length != func.length)) revert Mismatched_Array_Lengths();

        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of Account must be deployed with the new EntryPoint address, then upgrading
      * the implementation by calling `upgradeTo()`
     */
    function initialize(address initialAdmin, address initialDelegate) public virtual initializer {
        _initialize(initialAdmin, initialDelegate);
    }

    function _initialize(address initialAdmin, address initialDelegate) internal virtual {
        accessLevel[initialAdmin] = 2;
        accessLevel[initialDelegate] = 1;
        emit AccountInitialized(_entryPoint, initialAdmin, initialDelegate);
    }

    function addAdmin(address admin) public virtual onlyAdmin {
        _addAdmin(admin);
    }

    // NOTE: NO ACCESS CHECKS, ENFORCE ELSEWHERE
    function _addAdmin(address admin) internal virtual {
        accessLevel[admin] = 2;
        emit AdminAdded(msg.sender, admin);
    }

    function giveApproval(address target) public virtual onlyAdmin {
        _giveApproval(target);
    }

    // NOTE: NO ACCESS CHECKS, ENFORCE ELSEWHERE
    function _giveApproval(address target) internal virtual {
        accessLevel[target] = 1;
        emit ApprovalAdded(msg.sender, target);
    }

    function revokeApproval(address target) public virtual onlyAdmin {
        _revokeApproval(target);
    }

    // NOTE: NO ACCESS CHECKS, ENFORCE ELSEWHERE
    function _revokeApproval(address target) internal virtual {
        accessLevel[target] = 0;
        emit ApprovalRemoved(msg.sender, target);
    }    

    // Require the function call went through EntryPoint or admin
    // This does not also grant the ability for address's marked true in the
    // `isApproved` mapping to preserve the split in authority between 
    // admins who can trigger txns themselves vs approvals that only
    // grant an address the ability to produce a valid signature
    // for a user op originating from the entry point
    function _requireFromEntryPointOrAdmin() internal view {
        if (accessLevel[msg.sender] != 2 && msg.sender != address(entryPoint())) revert OnlyAdmin_Or_Entrypoint();
    }

    /// implement template method of BaseAccount
    /// signatures from addresses with an accessLevel > 0 can validate signature
    // NOTE: need to make validateSignature eip12721 compatible?
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        // Return fail value if recovered address accessLevel < 1
        if (accessLevel[hash.recover(userOp.signature)] < 1)
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value : msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyAdmin {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyAdmin();
    }
}