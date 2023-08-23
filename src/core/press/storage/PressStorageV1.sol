// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


// TODO: Research + get feedback on storage layout in general
//      particularly storage struct buckets
// TODO: missing UUPS storage gap

contract PressStorageV1 {

    /**
     * @notice Address of router contract
     */    
    address public router;

    /**
     * @notice Name of Press
     */        
    string public name;

    /**
     * @notice Pointer to encoded data stored at press level
     */    
    address public pressData;
}