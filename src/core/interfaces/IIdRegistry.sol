// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IIdRegistry {
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Tracks number of ids registered
     */
    function idCount() external view returns (uint256 count);    

    /**
     * @notice Tracks id registered to a given account
     */
    function idOwners(address account) external view returns (uint256 id);    

    /**
     * @notice Tracks backup address registered to a given id
     */
    function idBackups(uint256 id) external view returns (address backup);        

    //////////////////////////////////////////////////
    // ID REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @notice Register a new id by incrementing the idCount. Callable by anyone.
     *
     * @param backup      Address to set as backup for id
     * @param data        Aribtary data to emit in Register event
     */
    function register(address backup, bytes memory data) external returns (uint256 id);

    //////////////////////////////////////////////////
    // ID TRANSFER
    //////////////////////////////////////////////////    

    //////////////////////////////////////////////////
    // ID RECOVERY
    //////////////////////////////////////////////////        
}
