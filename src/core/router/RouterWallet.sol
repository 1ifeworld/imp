// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./aa/BaseAccount.sol";
import "./utils/TokenCallbackHandler.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title RouterWallet
 * @author Lifeworld
 *
 */
contract RouterWallet is
    BaseAccount,
    TokenCallbackHandler,
    FundsReceiver,
    ReentrancyGuard,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    struct SingleTargetInputs {
        address target;
        bytes4 selector;
        bytes data;
    }

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    event RiverWalletInitialized(IEntryPoint indexed entryPoint, address indexed initialOwner);

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    error Single_Target_Call_Failed(SingleTargetInputs inputs);
    error Call_Via_EntryPoint_Failed();
    error Sender_Not_EntryPoint();
    error Insufficient_Balance();

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    address public owner;
    IEntryPoint private immutable _entryPoint;
    // deposit amount cannot exceed type(uint112).max or else will revert in entry point stake manager
    mapping(address => uint256) public entryPointDepositMirror;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    //////////////////////////////////////////////////
    // INITIALIZERS
    //////////////////////////////////////////////////

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address initialOwner) public virtual initializer {
        _initialize(initialOwner);
    }

    function _initialize(address initialOwner) internal virtual {
        owner = initialOwner;
        emit RiverWalletInitialized(_entryPoint, owner);
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////


    function executeViaEntryPoint(bytes calldata userOpCalldata) external payable nonReentrant {
        if (msg.sender != address(_entryPoint)) revert Sender_Not_EntryPoint();
        /*
            userOpCalldata breakdown:
            bytes 0-20 will always contain the encoded target address
            bytes 20-52 will always contain the encoded uint256 msg.value needed for downstream fees
            bytes 52-end will always contain the encoded calldata to call the downstream target with
            bytes 52-72 will always contain the address of the original signer to pass through
                validation of signature authenticity happens during `validateUserOp` required
                by compatible wallets to have as defined in IAccount
        */
        // address target = userOpCalldata[0:20];
        (address target) = abi.decode(userOpCalldata[0:20], (address));
        (uint256 value) = abi.decode(userOpCalldata[20:52], (uint256));
        (address originalSigner) = abi.decode(userOpCalldata[52:72], (address));
        if (entryPointDepositMirror[originalSigner] < value) revert Insufficient_Balance();
        (bool success,) = target.call{value: value}(userOpCalldata[52:]);
        if (!success) revert Call_Via_EntryPoint_Failed();        
    }

    /// implement template method of BaseAccount
    /// NOTE: this isnt fully it because there isnt a check for if the UserOp is processed or not
    /// Probably need to do the deposit mirroring accounting somewhere else
    /// The eip4337 docs stipulate that:
    /// `the “signature” field usage is not defined by the protocol, but by each account implementation`
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {

        // Recover address that signed transaction to be submitted through River wallet
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address originSigner = hash.recover(userOp.signature);
        (address passThroughSigner) = abi.decode(userOp.callData[4:24], (address));
        // Signal op failutre if the signer being passed into calldata isnt the signer of the userOp
        if (originSigner != passThroughSigner) return SIG_VALIDATION_FAILED;
        return 0;       
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }    

    /// Hardcoding no ability to upgrade function for the moment
    function _authorizeUpgrade(address newImplementation) internal view override {}

    // /**
    //  * check current account deposit in the entryPoint
    //  */
    // function getDeposit() public view returns (uint256) {
    //     return entryPoint().balanceOf(address(this));
    // }

    // /**
    //  * check current account deposit in river wallet for given sender
    //  */
    // function getRiverDepositForAccount(address account) public view returns (uint256) {
    //     return entryPointDepositMirror[account];
    // }

    // /**
    //  * deposit more funds for this account in the entryPoint
    //  * AND track what account to deposit those funds for in RiverWallet
    //  */
    // function addDeposit(address account) public payable {
    //     entryPoint().depositTo{value: msg.value}(address(this));
    //     entryPointDepositMirror[account] = msg.value;
    // }

    // /**
    //  * withdraw value from the River Wallet's deposit in entry point
    //  * ensure that sender is not withdrawing more than they have allocated to River wallet
    //  * @param withdrawAddress target to send to
    //  * @param amount to withdraw
    //  */
    // function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public {
    //     if (amount > entryPointDepositMirror[msg.sender]) revert Withdrawal_Exceeds_Funds();
    //     entryPoint().withdrawTo(withdrawAddress, amount);
    // }

    // //
    // function callTarget(SingleTargetInputs calldata callInputs) external payable nonReentrant {
    //     (bool success,) = callInputs.target.call{value: msg.value}(
    //         abi.encodePacked(callInputs.selector, abi.encode(msg.sender, callInputs.data))
    //     );
    //     if (!success) revert Single_Target_Call_Failed(callInputs);
    // }

    // function executeViaEntryPoint() external payable {
    //     if (msg.sender != address(entryPoint())) revert Sender_Not_EntryPoint();
    // }
}
