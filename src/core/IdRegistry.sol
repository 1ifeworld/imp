// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IdRegistry
 */
contract IdRegistry {

    event Register(address indexed to, uint256 indexed id, address indexed delegate, address backup);

    /// @dev Revert when the destination must be empty but has an rid.
    error HasId();    

    uint256 public idCounter;
    mapping(address => uint256) public idOwners;
    mapping(uint256 => address) public idDelegates;
    mapping(uint256 => address) public idBackups;

    function register(address delegate, address backup) external returns (uint256 rid) {
        // Cache msg.sender
        address sender = msg.sender;

        /* Revert if the target(to) has an rid */
        if (idOwners[sender] != 0) revert HasId();

        /* Safety: idCounter won't realistically overflow. */
        unchecked {
            /* Incrementing before assignment ensures that no one gets the 0 fid. */
            rid = ++idCounter;
        }        

        // Assign rid + delegate + backup + emit for indexing
        idOwners[sender] = rid;
        idDelegates[rid] = delegate;
        idBackups[rid] = backup;
        emit Register(sender, rid, delegate, backup);        
    }      
}