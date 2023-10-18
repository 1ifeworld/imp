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
        // Increments id and assign owner
        idOwners[sender] = id = ++idCount;
        // Assign backup for id
        idBackups[id] = backup;
        emit Register(sender, id, backup, data);        
    }
}