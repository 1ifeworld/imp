// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {IIdRegistry} from "./interfaces/IIdRegistry.sol";

/**
 * @title IdRegistry
 * @author Lifeworld
 */
contract IdRegistry is IIdRegistry {

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
     *      NOTE: add description
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
     *      NOTE: add params + description
     *      
     */
    event TransferInitiated(address indexed from, address indexed to, uint256 indexed id);    

    /**
     * @dev Emit an event when an id transfer is cancelled
     *
     *      NOTE: add params + description
     *      
     */
    event TransferCancelled(address indexed from, address indexed to, uint256 indexed id);     

    /**
     * @dev Emit an event when an id is transferred
     *
     *      NOTE: add params + description
     *      
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
        emit TransferComplete({from: from, to: to, id: id});
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
}