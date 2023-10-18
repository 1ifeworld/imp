// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {IdRegistry} from "./IdRegistry.sol";

/**
 * @title DelegateRegistry
 * @author Lifeworld
 */
contract DelegateRegistry {

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////   

    /// @dev Revert when msg.sender is not the target id owner
    error Only_Id_Owner();    

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    /**
     * @dev Emit an event when an id grants a delegation
     *
     *      NOTE: add description
     *
     * @param id            The id granting delegation
     * @param nonce         The current transfer nonce of id
     * @param target        Address receiving delegation
     */
    event Delegate(uint256 indexed id, uint256 nonce, address indexed target);

    /**
     * @dev Emit an event when an id removes a delegation
     *
     *      NOTE: consider merging both delegate events into one with a true/false flag param
     *      NOTE: add description
     *
     * @param id            The id removing delegation
     * @param nonce         The current transfer nonce of id
     * @param target        Address losing delegation
     */
    event DelegateRemoved(uint256 indexed id, uint256 nonce, address indexed target);    

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////         

    constructor(address _idRegistry) {
        idRegistry = IdRegistry(_idRegistry);
    }

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////        

    IdRegistry immutable public idRegistry;

    // id => transferNonce => account => T/F delegate value
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public idDelegates;

    //////////////////////////////////////////////////
    // ID DELEGATION
    //////////////////////////////////////////////////    

    function delegate(uint256 id, address target) external {
        // Cache msg.sender
        address sender = msg.sender;
        // Check if sender is id custody address
        if (idRegistry.idOwnedBy(sender) != id) revert Only_Id_Owner();
        // Retrieve current transfer nonce for id
        uint256 idTransferNonce = idRegistry.transferCountForId(id);
        // Delegate to target for given id + transfer nonce
        idDelegates[id][idTransferNonce][target] = true;
        emit Delegate(id, idTransferNonce, target);
    }

    function removeDelegation(uint256 id, address target) external {
        // Cache msg.sender
        address sender = msg.sender;
        // Check if sender is id custody address
        if (idRegistry.idOwnedBy(sender) != id) revert Only_Id_Owner();       
        // Retrieve current transfer nonce for id
        uint256 idTransferNonce = idRegistry.transferCountForId(id); 
        // Remove delegation from target for given id + transfer nonce
        idDelegates[id][idTransferNonce][target] = false;
        emit DelegateRemoved(id, idTransferNonce, target);                
    }

    function isDelegate(uint256 id, address target) external view returns (bool delegateStatus) {
        delegateStatus = idDelegates[id][idRegistry.transferCountForId(id)][target];
    }
}