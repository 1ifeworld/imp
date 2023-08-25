// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {ILogic} from "../../../../core/press/interfaces/ILogic.sol";
import {IPressTransmitter} from "../press/interfaces/IPressTransmitter.sol";

contract LogicTransmitterMerkleAdmin is ILogic {
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

    /* ~~~ Access Control Requests ~~~ */    

    // NOTE:
    //  sender in inputs = the account initiating txn at router
    //  msg.sender = the press calling getPressDataAccess in its `updatePressData` call
    function getPressDataAccess(address sender) external view returns (bool) {
        // Grant access to sender if they are admin, deny if not
        return pressAdmins[msg.sender][sender] ? true : false;
    }        

    // NOTE:
    //  sender in inputs = the account initiating txn at router
    //  msg.sender = the press calling getSendAccess in its `handleSend` call
    function getSendAccess(address sender, uint256 quantity, bytes32[] memory merkleProof)
        external
        view
        returns (bool)
    {
        // return MerkleProofLib.verify(merkleProof, pressMerkleRoot[msg.sender], keccak256(abi.encodePacked(sender)));
        // NOTE: currently have hardcoded included address in for testing
        return MerkleProofLib.verify(merkleProof, pressMerkleRoot[msg.sender], keccak256(abi.encodePacked(sender)));
    }

    // NOTE:
    //  sender in inputs = the account initiating txn at router
    //  msg.sender = the press calling getSendAccess in its `handleOverwrite` call
    function getOverwriteAccess(address sender, uint256 id) external view returns (bool) {
        // Grant access to sender if they are an admin
        if (pressAdmins[msg.sender][sender]) return true;
        // Grant access to sender if they are the originator of the id
        if (IPressTransmitter(msg.sender).getIdOrigin(id) == sender) return true;
        // Deny access to sender if none of the above is true
        return false;
    }

    // NOTE:
    //  sender in inputs = the account initiating txn at router
    //  msg.sender = the press calling getRemoveAccess in its `handleRemove` call
    function getRemoveAccess(address sender, uint256 id) external view returns (bool) {
        // Grant access to sender if they are an admin
        if (pressAdmins[msg.sender][sender]) return true;
        // Grant access to sender if they are the originator of the id
        if (IPressTransmitter(msg.sender).getIdOrigin(id) == sender) return true;
        // Deny access to sender if none of the above is true
        return false;
    }    
    
    /* ~~~ Admin Interactions ~~~ */

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
