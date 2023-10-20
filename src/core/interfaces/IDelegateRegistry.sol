// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IdRegistry} from "../IdRegistry.sol";

interface IDelegateRegistry {
    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////    

    /**
     * @notice Address of idRegistry
     */
    function idRegistry() external view returns (IdRegistry);    
    
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Tracks value status for given id => transferNonce => target => status
     */
    function idDelegates(uint256 id, uint256 transferNonce, address target) external view returns (bool);
   
    //////////////////////////////////////////////////
    // DELEGATION REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @notice Update delegate status for a given target and id
     *
     * @param id        Id to update delegate for
     * @param target    Address to target for delegation
     * @param status    T/F value of delegation status
     */    
    function updateDelegate(uint256 id, address target, bool status) external;  

    //////////////////////////////////////////////////
    // DELEGATION VIEW
    //////////////////////////////////////////////////    

    /**
     * @notice View current delegate status for given target and id
     *
     * @param id        Id to update delegate for
     * @param target    Address to target for delegation
     */   
    function isDelegate(uint256 id, address target) external view returns (bool delegateStatus);
}
