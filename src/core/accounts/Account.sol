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
    //////////////////////////////////////////////////
    // TYPES NOTE: move to Interface
    //////////////////////////////////////////////////      

    struct Call {
        address target;
        bytes4 selector;
        uint256 value;
    }
    
    //////////////////////////////////////////////////
    // CUSTOM FUNCTIONALITY
    //////////////////////////////////////////////////        
    using ECDSA for bytes32; // hash.recover()
    using MessageHashUtils for bytes32; // hash.toEthSignedMessageHash()

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////  

    error Only_Owner();
    error OnlyOwner_Or_Entrypoint();
    error Array_Length_Mismatch();   

    /// x x x x x x 
    
    error Only_Admin();
    error OnlyAdmin_Or_Entrypoint();
     
    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////  

    event AccountInitialized(IEntryPoint indexed entryPoint, address indexed owner, Call[] indexed approvedCalls);
    event CallRegistered(address indexed actor, bytes32 callHash, bool approved);    

    /// x x x x x x 

    event AccountInitialized(IEntryPoint indexed entryPoint, address indexed admin, address indexed delegate);
    event AdminAdded(address indexed sender, address indexed admin);
    event ApprovalAdded(address indexed sender, address indexed target);
    event ApprovalRemoved(address indexed sender, address indexed target);

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////      

    IEntryPoint private immutable _entryPoint;

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////          

    // address of account owner
    address public owner;

    // address sender => abi.encode(Call{address target, bytes4 selector, uitn256 value}) => approved T/F
    mapping(address => mapping(bytes32 => bool)) public callApprovals;

    /// x x x x 

    mapping(address => uint256) public accessLevel;    

    //////////////////////////////////////////////////
    // MODIFIERS
    //////////////////////////////////////////////////    

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// x x x x x

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////      

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }    

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////      

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function _onlyOwner() internal view {
        // directly from account owner, or through the account itself (which gets redirected through execute())
        if (msg.sender != owner && msg.sender != address(this)) revert Only_Owner();

        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }    

    /// x x x x x x

    // NOTE: could potentially change the require to check if access > 1
    function _onlyAdmin() internal view {
        // directly from admin, or through the account itself (which gets redirected through execute())
        if (accessLevel[msg.sender] != 2 && msg.sender != address(this)) revert Only_Admin();
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        
        _requireFromEntryPointOrOwner();
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
    function initialize(address initialOwner, address[] memory actors, Call[] memory calls) public virtual initializer {
        _initialize(initialOwner, actors, calls);
    }

    function _initialize(address initialOwner, address[] memory actors, Call[] memory calls) internal virtual {
        owner = initialOwner;
        
        // NOTE: add this back in
        // emit AccountInitialized(_entryPoint, initialOwner);

        if (actors.length != calls.length) revert Array_Length_Mismatch();

        for (uint256 i; i < calls.length; ++i) {
            bytes32 callHash = getCallHash(calls[i]);
            callApprovals[actors[i]][callHash] = true;
            emit CallRegistered(actors[i], callHash, true);
        }
    }


    function registerCalls(address[] memory actors, Call[] memory calls, bool[] memory approvals) onlyOwner external {
        if (actors.length != calls.length || actors.length != approvals.length) revert Array_Length_Mismatch();
        for (uint256 i; i < actors.length; ++i) {
            bytes32 callHash = getCallHash(calls[i]);
            callApprovals[actors[i]][callHash] = approvals[i];
            emit CallRegistered(actors[i], callHash, approvals[i]);
        }
     }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        if (msg.sender != owner && msg.sender != address(entryPoint())) revert OnlyOwner_Or_Entrypoint();
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

        // // abi.encode(execute.selector, execute.data)
        // bytes memory data = userOp.calldata
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

    // HELPERS
function getCallHash(Call memory call) public pure returns (bytes32) {
    return keccak256(abi.encode(call.target, call.selector, call.value));
}    
}
