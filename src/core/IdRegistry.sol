// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Nonces} from "openzeppelin-contracts/utils/Nonces.sol";
import {Signatures} from "./lib/Signatures.sol";
import {EIP712} from "./lib/EIP712.sol";

/*
    Signatures, EIP712, and Nonces in place to add
    Transfer + Recovery functionality
*/

/**
 * @title IdRegistry
 */
contract IdRegistry is Signatures, EIP712("name", "symbol"), Nonces  {
    
    error HasId();     

    event Register(address indexed to, uint256 indexed id, address backup);

    uint256 public idCounter;    
    mapping(address => uint256) public idOwner;
    mapping(uint256 => address) public idBackup;

    function register(address backup) external returns (uint256 id) {
        address sender = msg.sender;
        if (idOwner[sender] != 0) revert HasId();
        unchecked {
            id = ++idCounter;
        }
        idOwner[sender] = id;
        idBackup[id] = backup;
        emit Register(sender, id, backup);        
    }      
}