// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IIdRegistry} from "./interfaces/IIdRegistry.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title IdRegistry
 * @author Lifeworld
 */
contract IdRegistry is IIdRegistry {

    // TODO: Add in trusted recovery functionality

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////   

    /// @dev Revert when the destination must be empty but has an id.
    error HasId();    

    /// @dev Revert when the caller must have an id but does not have one.
    error HasNoId();

    /// @dev Revert when caller is not designated transfer recipient
    error Not_Transfer_Recipient();

    /// @dev Revert when caller is not designated transfer initiator
    error Not_Transfer_Initiator();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    /**
     * @dev Emit an event when a new id is registered
     *
     *      Ids are unique identifiers that can be registered to an address an neve repeat
     *
     * @param to            Address of the account calling `registerNode()`
     * @param id            The id being registered
     * @param backup        Address assigned as a backup for the given id
     * @param data          Data to be associated with registration of id
     */
    event Register(address indexed to, uint256 indexed id, address backup, bytes data);

    /**
     * @dev Emit an event when an id transfer is initiated
     *
     * @param from      Where the id is being transfered from
     * @param to        The destination of id if transfer is completed
     * @param id        The id being transfered
     */
    event TransferInitiated(address indexed from, address indexed to, uint256 indexed id);    

    /**
     * @dev Emit an event when an id transfer is cancelled
     *
     * @param from      Where the id is being transfered from
     * @param to        The destination of id if transfer is completed
     * @param id        The id being transfered
     */
    event TransferCancelled(address indexed from, address indexed to, uint256 indexed id);     

    /**
     * @dev Emit an event when an id is transferred
     *
     * @param from      Where the id is being transfered from
     * @param to        The destination of id if transfer is completed
     * @param id        The id being transfered
     */
    event TransferComplete(address indexed from, address indexed to, uint256 indexed id);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////        

    /**
     * @inheritdoc IIdRegistry
     */
    uint256 public idCount;

    /**
     * @inheritdoc IIdRegistry
     */
    mapping(address => uint256) public idOwnedBy;

    /**
     * @inheritdoc IIdRegistry
     */    
    mapping(uint256 => address) public backupForId;    

    /**
     * @inheritdoc IIdRegistry
     */  
    mapping(uint256 => uint256) public transferCountForId;

    /**
     * @dev Stores pendingTransfers info for all ids
     *
     * @custom:param id     Numeric id
     */
    mapping(uint256 => PendingTransfer) public pendingTransfers;

    //////////////////////////////////////////////////
    // VIEWS
    //////////////////////////////////////////////////    

    /**
     * @inheritdoc IIdRegistry
     */  
    function transferPendingForId(uint256 id) external view returns (PendingTransfer memory) {
        return pendingTransfers[id];
    }

    //////////////////////////////////////////////////
    // ID REGISTRATION
    //////////////////////////////////////////////////    

    /**
     * @inheritdoc IIdRegistry
     */
    function register(address backup, bytes calldata data) external returns (uint256 id) {
        // Cache msg.sender
        address sender = msg.sender;        
        // Revert if the sender already has an id
        if (idOwnedBy[sender] != 0) revert HasId();    
        // Increment idCount
        id = ++idCount;
        // Increment transfer count for target id. Registration will always be 0 => 1
        ++transferCountForId[id];
        // Assign id to owner
        idOwnedBy[sender] = id;
        // Assign backup to id
        backupForId[id] = backup;
        emit Register(sender, id, backup, data);        
    }

    //////////////////////////////////////////////////
    // ID TRANSFER
    //////////////////////////////////////////////////       

    /**
     * @inheritdoc IIdRegistry
     */    
    function initiateTransfer(address recipient) external {
        // Cache msg.sender
        address sender = msg.sender;
        // Retrieve id for given sender
        uint256 fromId = idOwnedBy[sender];        
        // Check if sender has an id
        if (fromId == 0) revert HasNoId();
        // Update pendingTransfers storage
        pendingTransfers[fromId] = PendingTransfer({
            from: sender,
            to: recipient
        });
        emit TransferInitiated({from: sender, to: recipient, id: fromId});
    }

    /**
     * @inheritdoc IIdRegistry
     */    
    function acceptTransfer(uint256 id) external {
        // Reterieve pendingTransfer info for givenId
        PendingTransfer storage pendingTransfer = pendingTransfers[id];
        // Check if msg.sender is recipient address
        if (msg.sender != pendingTransfer.to) revert Not_Transfer_Recipient();
        // Check that pendingTransfer.to doesn't already own id
        if (idOwnedBy[pendingTransfer.to] != 0) revert HasId();
        // Execute transfer process
        _unsafeTransfer(id, pendingTransfer.from, pendingTransfer.to);
    }

    /**
     * @inheritdoc IIdRegistry
     */ 
    function cancelTransfer(uint256 id) external {
        // Reterieve pendingTransfer info for givenId
        PendingTransfer storage pendingTransfer = pendingTransfers[id];
        // Check if msg.sender is "from" address
        if (msg.sender != pendingTransfer.from) revert Not_Transfer_Initiator();        
        // Clear pendingTransfer for given id
        delete pendingTransfers[id];
        emit TransferCancelled({from: pendingTransfer.from, to: pendingTransfer.to, id: id});
    }

    /**
     * @dev Transfer id without checking invariants
     */    
    function _unsafeTransfer(uint256 id, address from, address to) internal {
        // Assign ownership of designated id to "to" address
        idOwnedBy[to] = id;
        // Delete ownership of designated id from "from" address
        delete idOwnedBy[from];
        // Increment id transfer count to clear delegations from DelegateRegistry
        ++transferCountForId[id];
        // Clear pendingTransfer storage for given id
        delete pendingTransfers[id];
        // Emit event for indexing
        emit TransferComplete(from, to, id);
    }

    //////////////////////////////////////////////////
    // ID RECOVERY
    //////////////////////////////////////////////////      

    /* 
        NOTE: initial ideas
        
        Basically same thing as transfer process but can be triggered
        by previously set "backup" address for given id

        also need to add in a "change backup address" function,
        potentially with similar transfer nonce pattern
    */

    //////////////////////////////////////////////////
    // ID ATTESTATION
    //////////////////////////////////////////////////            

    // NOTE: allow addresses to attest they are controlled by the same 
    //      user who is in custody of an Id

    // Must be submitted by id owner
    // Passing in signature of the account they are trying to attest for

    using ECDSA for bytes32; // hash.recover() + has.ethSignedMessagehash()
    // using MessageHashUtils for bytes32; // hash.toEthSignedMessageHash()      

    error HasAttested();       
    error NonexistentId();       
    error InvalidSignature();       

    mapping(address => uint256) public attestedBy;    
    mapping(address => mapping(uint256 => uint256)) attestedByWithNonce;

    // This function msut be called by the smart account that owns the id
    // In terms of evoking this call correctly
    /*

        1. User completes OTP auth into their smart account that owns id #x
        2. User optionally decides to sign-in with their EOA/other smart wallet that owns ENS (ex: gnosis)
           via WalletConnect or other wallet provider
        3. User fills in input field for ENS they would like to link to their id
           If their ENS is registered to a smart account, this is when we can get this value
           to pass into the attest function
        3. River prompts user to generate a signature. This is a standard sign method for EOAs,
           slightly unclear what this would be if users connect via multisig (I think should be the same)
        4. River generates a userOp for the custody address of the id, which gets signed by the users
           Privy EOA which is the signer for their smart account that will execute the transation
           *** because its a userOp, we can cover the gas for this

    */
    function attest(address optionalSmartSigner, bytes32 hash, bytes calldata signature) external {
        // Cache custodyAddress aka msg.sender
        address custodyAddress = msg.sender;
        // Reterieve id for custody address
        uint256 id = idOwnedBy[custodyAddress];  
        // Generate hash for check via recover
        bytes32 messsageHash = hash.toEthSignedMessageHash();        
        // Attempt to recover attestor address
        address attestor = messsageHash.recover(signature);    
        // Check if address was recovered successfuly
        // If attestor != address(0), it was a valid signature. Now check they havent already attested elsewhere
        if (attestor != address(0)) {
            if (attestedBy[attestor] != 0) revert HasAttested();
            // Store attestation
            attestedBy[attestor] = id;
        } else {
            // If attestor == address(0), address wasnt successfuly ecdsa receovered, attempt ERC1271 signature verification
            if (!SignatureChecker.isValidERC1271SignatureNow(optionalSmartSigner, messsageHash, signature)) revert InvalidSignature();
            // Store attestation
            attestedBy[optionalSmartSigner] = id;
        } 
    }


//         // // // Check for valid signature
//         // // if (!SignatureChecker.isValidSignatureNow(sender, hash, digest)) revert InvalidSignature();
//         // // Cache sender address
//         // address sender = msg.sender;
//         // // Fetch id for sender
//         // if ()
//         // // Revert if target id has already been attested for
//         // if (id > idCount) revert NonexistentId();
//         // // Revert if sender has already attested for an existing id
//         // if (attestedBy[sender] != 0) revert HasAttested();

//    function verifyFidSignature(
//         address custodyAddress,
//         uint256 fid,
//         bytes32 digest,
//         bytes calldata sig
//     ) external view returns (bool isValid) {
//         isValid = idOf[custodyAddress] == fid && SignatureChecker.isValidSignatureNow(custodyAddress, digest, sig);
//     }
}