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
    error Not_Target_Recipient();

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
     * @dev Emit an event when an id is transferred
     *
     *      NOTE: add params + description
     *      
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

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
    mapping(address => uint256) public idOwners;

    /**
     * @inheritdoc IIdRegistry
     */    
    mapping(uint256 => address) public idBackups;    

    // TRANSFER FUNCTIONALITY BELOW
    /*
        NOTE: explnation of what this is doing

        1. everytime an id is assigned to an owner (via register or transfer)
           the the transfer count is incremented
        2. the delegate registry takes into account ownership transfers

    */
    mapping(uint256 => uint256) public idTransferCount;

    mapping(uint256 => PendingTransfer) public idTransferPending;

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
        if (idOwners[sender] != 0) revert HasId();    
        // Increment idCount
        id = ++idCount;
        // Increment id specific transfer nonce. Registration will always be 0 => 1
        ++idTransferCount[id];
        // Increments id and assign owner
        idOwners[sender] = id;
        // Assign backup for id
        idBackups[id] = backup;
        emit Register(sender, id, backup, data);        
    }

    //////////////////////////////////////////////////
    // ID TRANSFER
    //////////////////////////////////////////////////       

    // can only be called by custody address of id
    // although recipient can be set as zero address
    //      there is no ability for zero addrss to actually claim the id
    // dont need to include check if recipient already has an id
    //      because that check occurs on the accept side
    // invariant 1: address(0) cannot trigger transfer
    function initiateTransfer(address recipient) external {
        // Cache msg.sender
        address sender = msg.sender;
        // Retrieve id for given sender
        uint256 fromId = idOwners[sender];        
        // Check if sender has an id
        if (fromId == 0) revert HasNoId();
        // set pendingTransfer info for id. address marked as to can claim it now,
        //      and address marked as from will have their ownership storage cleared if
        //      transfer is processed
        idTransferPending[fromId] = PendingTransfer({
            from: sender,
            to: recipient
        });
        // NOTE: Emit some type of TransferInitiated event
    }

    // dont need a check on if id has been registeed before
    //      because only owners of an id can trigger a transfer request
    // invariant 1: address(0) cannot accept transfer
    function acceptTransfer(uint256 id) external {
        // Reterieve pendingTransfer info for givenId
        PendingTransfer storage pendingTransfer = idTransferPending[id];
        // Check if msg.sender is recipient address
        if (msg.sender != pendingTransfer.to) revert Not_Target_Recipient();
        // Check that pendingTransfer.to doesn't already own id
        if (idOwners[pendingTransfer.to] != 0) revert HasId();
        // Execute transfer process
        _unsafeTransfer(id, pendingTransfer.from, pendingTransfer.to);
    }

    // can only be called by from address of pendingTranfer
    function cancelTransfer(uint256 id) external {
        // Reterieve pendingTransfer info for givenId
        PendingTransfer storage pendingTransfer = idTransferPending[id];
        // Check if msg.sender is "from" address
        if (msg.sender != pendingTransfer.from) revert Not_Transfer_Initiator();        
        // Clear pendingTransfer for given id
        delete idTransferPending[id];
        // NOTE emit some type of "Transfer Cancelled" event
    }

    /**
     * @dev Transfer id without checking invariants
     */    
    function _unsafeTransfer(uint256 id, address from, address to) internal {
        // Assign ownership of designated id to "to" address
        idOwners[to] = id;
        // Delete ownership of designated id from "from" address
        delete idOwners[from];
        // Increment id transfer nonce to clear delegations from DelegateRegistry
        ++idTransferCount[id];
        // Clear pendingTransfer storage for given id
        delete idTransferPending[id];
        // Emit event for indexing
        emit Transfer(from, to, id);
    }

    //////////////////////////////////////////////////
    // ID RECOVERY
    //////////////////////////////////////////////////      

    /* 
        NOTE: initial ideas
        
        Something similar to transfer process but can be triggered
        by previously set "backup" address for given id
    */
}