// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IIdRegistry} from "./interfaces/IIdRegistry.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
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
        // Clear existing attestation for id if relevant
        _unsafeAttemptRevokeAttestation(id);
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

    using ECDSA for bytes32; // hash.recover() + has.ethSignedMessagehash() 

    error HasAttested();       
    error NonexistentId();       
    error InvalidSignature();    
    error Not_Attestor();    

    event Attest(uint256 indexed id, address indexed attestor);   
    event RevokeAttestation(uint256 indexed id, address indexed attestor);   

    mapping(address => uint256) public attestedBy;    
    mapping(uint256 => address) public attestedFor;

    // NOTE: allow addresses to attest they are controlled by the same 
    //      user who is in custody of an Id
    // NOTE: Must be submitted by id owner
    // NOTE: Passing in signature of the account they are trying to attest for
    function attest(bytes32 hash, bytes calldata signature, address contractSignerOverride) external {
        // Cache msg.sender. 
        address sender = msg.sender;
        // Reterieve id for sender address
        uint256 id = idOwnedBy[sender];      
        // Check if contractSigner override is present
        if (contractSignerOverride == address(0)) {
            // Attempt to recover attestor address from EOA signature
            address attestor = hash.recover(signature);    
            // Check they havent already attested for another id
            if (attestedBy[attestor] != 0) revert HasAttested();
            // Store attestation - double storage so that attestations can be automtically cleared on id trasnfers
            attestedBy[attestor] = id;
            attestedFor[id] = attestor;
            emit Attest(id, attestor);
        } else {
            // constractSignerOverride was present, attempt ERC1271 signature verification
            if (!SignatureChecker.isValidERC1271SignatureNow(contractSignerOverride, hash, signature)) revert InvalidSignature();
            // Check they havent already attested for another id
            if (attestedBy[contractSignerOverride] != 0) revert HasAttested();            
            // Store attestation - double storage so that attestations can be automtically cleared on id trasnfers
            attestedBy[contractSignerOverride] = id;
            attestedFor[id] = contractSignerOverride;
            emit Attest(id, contractSignerOverride);
        } 
    }

    // Revoke Attestation callable by anyone
    function reovkeAttestation(uint256 id) external {
        // Cache msg.sender
        address sender = msg.sender;
        // Revert if sender is not attestor for target id
        if (sender != attestedFor[id]) revert Not_Attestor();
        // Clear storage for attestations
        delete attestedFor[id];
        delete attestedBy[sender];
        // Emit for indexing
        emit RevokeAttestation(id, sender);
    }        

    // Revoke Attestation function without invariant checks. Must Enforce elsewhere
    function _unsafeAttemptRevokeAttestation(uint256 id) internal {
        // Retrieve attestor address
        address attestor = attestedFor[id];
        // If attestor != address(0), clear storage and emit revoke event
        if (attestor != address(0)) {
            // Clear storage for attestations
            delete attestedFor[id];
            delete attestedBy[attestor];
            // Emit for indexing
            emit RevokeAttestation(id, attestor);
        }
    }
}