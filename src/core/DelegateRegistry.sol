// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IdRegistry} from "./IdRegistry.sol";

/**
 * @title DelegateRegistry
 */
contract DelegateRegistry {
    
    error No_Delegate_Access(); 
    
    event Delegate(address sender, uint256 indexed id, address indexed delegate, uint256 access);

    enum AccessLevel {        
        NONE,
        LIMITED,
        FULL
    }
    
    IdRegistry public immutable idRegistry;
    mapping(uint256 => mapping(address => AccessLevel)) public idDelegateAccess;

    constructor(address _idRegistry) {
        idRegistry = IdRegistry(_idRegistry);
    }
    function delegate(uint256 id, address target, AccessLevel accessLevel) external {
        address sender = msg.sender;
        if (idRegistry.idOwner(sender) != id && idDelegateAccess[id][target] < AccessLevel.FULL) 
            revert No_Delegate_Access();
        idDelegateAccess[id][target] = accessLevel;
        emit Delegate(sender, id, target, uint256(accessLevel));      
    }      
}