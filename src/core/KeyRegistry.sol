// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*
    NOTE: comments on design

    potentially want to add a delay mechanism (7 days?) that allows 
    trustedCallers to set a backup/recovery address that can freeze
    specific caller access in the case of an exploit

    also want to explore if it makes sense to actually only be letting
    trusted callers authorize transactiosn for given ids
    ex: managers can only approve trustedCallers, cant make calls themselves
        AND owner of registry is only one who can propose trustedCallers

    NEXT:
    
    experiment with concept of the deploy/owner of registry being able to set
    allowed trustCallers that ids can approve

    experiment with moving literally all of this to event based system
        pretty sure that actually nothing needs to be stored in contract storage
        and that events work for everything 
*/

/**
 * @title KeyRegistry
 * NOTE: this implemnetation introduces an id system that abstracts
 *      who who is allowed to sign approvals as id, 
 *      and who is allowed to do things given those approvals
 */
contract KeyRegistryWithIds  {

    error Nonexistent_Id();
    error No_Sender_Access();

    uint256 idCounter;
    // { uint256 id => address identity => bool status }
    mapping(uint256 => mapping(address => bool)) public idManagers;
    // { uint256 id => address trustedCaller => bool status }
    mapping(uint256 => mapping(address => bool)) public idTrustedCallers;
    // { uint256 id => address primaryDisplay }
    mapping(uint256 => address) public idDisplay;

    function newId(address trustedCaller) public returns (uint256 id) {
        // increment idCounter
        ++idCounter;
        // set initial upstreamIdentity
        idManagers[idCounter][msg.sender] = true;
        // set initial allowedSigner
        if (trustedCaller != address(0)) {
            idTrustedCallers[idCounter][trustedCaller] = true; 
        }
        // return new id
        return idCounter;
    }

    function updateManagers(uint256 id, address manager, bool status) public {
        if (id < idCounter) revert Nonexistent_Id();
        // Cache msg.sender
        address caller = msg.sender;     
        // Check if caller has access to update managers for target id   
        if (!idManagers[id][caller]) revert No_Sender_Access(); 
        // Assign status to target manager for target id
        idManagers[id][manager] = status;
    }

    function updateManagersTrusted(uint256 id, address manager, bool status) public {
        if (id < idCounter) revert Nonexistent_Id();
        // Cache msg.sender
        address caller = msg.sender;     
        // Check if caller has access to update managers for target id   
        if (!idTrustedCallers[id][caller]) revert No_Sender_Access(); 
        // Assign status to target manager for target id
        idManagers[id][manager] = status;
    }    

    function updateCallersForId(uint256 id, address trustedCaller, bool status) public {
        if (id < idCounter) revert Nonexistent_Id();
        // Cache msg.sender
        address caller = msg.sender;     
        // Check if caller has access to update managers for target id   
        if (!idManagers[id][caller]) revert No_Sender_Access(); 
        // Assign status to target trustedCaller for target id
        idTrustedCallers[id][trustedCaller] = status;        
    }

    function updateCallersForIdTrusted(uint256 id, address trustedCaller, bool status) public {
        if (id < idCounter) revert Nonexistent_Id();
        // Cache msg.sender
        address caller = msg.sender;     
        // Check if caller has access to update trustedCallers for target id   
        if (!idTrustedCallers[id][caller]) revert No_Sender_Access(); 
        // Assign status to target trustedCaller for target id
        idTrustedCallers[id][trustedCaller] = status;        
    }    

    // NOTE: this function does not have a trusted variant
    function setIdPrimaryDisplay(uint256 id, address display) public {
        if (id < idCounter) revert Nonexistent_Id();
        // Cache msg.sender
        address caller = msg.sender;     
        // Check if caller has access to update primaryDisplay for target id   
        if (!idManagers[id][caller]) revert No_Sender_Access(); 
        // Assign status to target trustedCaller for target id
        idDisplay[id] = display;    
    }
}

/**
 * @title KeyRegistryNoIds
 * NOTE: this implemnetation uses ethereum addresses directly as identity
 */
contract KeyRegistryNoIds  {

    // no id system design
}