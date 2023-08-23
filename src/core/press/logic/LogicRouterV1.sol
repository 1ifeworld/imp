// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {ILogic} from "./ILogic.sol";

contract LogicRouterV1 is ILogic {

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////    

    mapping(address => bytes32) public pressMerkleRoot;
    mapping(address => mapping(address => bool)) public pressAdmins;
    
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event MerkleRootSet(address press, bytes32 merkleRoot);
    event AccountRolesSet(address press, address[] accounts, bool[] roles);     

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////    

    error Sender_Not_Admin();
    error Invalid_Input_Length();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////    

    //////////////////////////////
    // EXTERNAL
    ////////////////////////////// 

    function transmitRequest(
        address sender, 
        uint256 quantity, 
        bytes32[] memory merkleProof
    ) external view returns (bool) {
        return MerkleProofLib.verify(merkleProof, pressMerkleRoot[msg.sender], keccak256(abi.encodePacked(sender)));
    } 

    function initializeWithData(bytes memory data) external {
        // Cache sender address
        address sender = msg.sender;
        // Decode incoming data
        (address[] memory accounts, bytes32 merkleRoot) = abi.decode(data, (address[], bytes32));
        // Set merkle root
        pressMerkleRoot[sender] = merkleRoot;        
        // Grant admin roles
        for (uint256 i; i < accounts.length; ++i) {
            pressAdmins[sender][accounts[i]] = true;
        }
        // Emit merkle root and admins
        emit MerkleRootSet({press: sender, merkleRoot: merkleRoot});
        emit AccountRolesSet({press: sender, accounts: accounts, roles: _arrayOfTrues(accounts.length)});
    }

    function setMerkleRoot(address press, bytes32 merkleRoot) external {
        if (pressAdmins[press][msg.sender] != true) revert Sender_Not_Admin();
        pressMerkleRoot[press] = merkleRoot;
        emit MerkleRootSet({press: press, merkleRoot: merkleRoot});
    }

    function setAccountRoles(address press, address[] memory accounts, bool[] memory roles) external {
        if (pressAdmins[press][msg.sender] != true) revert Sender_Not_Admin();
        if (accounts.length != accounts.length) revert Invalid_Input_Length();
        for (uint256 i; i < accounts.length; ++i) {
            pressAdmins[press][accounts[i]] = roles[i];
        }
        emit AccountRolesSet({press: press, accounts: accounts, roles: roles});
    }    

    //////////////////////////////
    // INTERNAL
    ////////////////////////////// 

    function _arrayOfTrues(uint256 length) internal pure returns (bool[] memory) {
        bool[] memory truesArray = new bool[](length);
        for (uint256 i; i < length; ++i) {
            truesArray[i] = true;
        }
        return truesArray;
    }
}