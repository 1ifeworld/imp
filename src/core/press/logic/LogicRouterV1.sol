// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1967Proxy} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {ILogic} from "./ILogic.sol";

contract LogicRouterV1 is ILogic {

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////    

    mapping(address => mapping(address => bool)) pressAdmins;
    mapping(address => bytes32) pressMerkleRoot;
    
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////    

    function initializeWithData(bytes memory data) external {
        (address[] memory accounts, bytes32 merkleRoot) = abi.decode(data, (address[], bytes32));
        _grantAdminRole(msg.sender, accounts);

    }

    // NOTE: NO ACCESS CONTROL. ENFORCE ELSEWHERE
    function _setAccountRoles(address press, address[] memory accounts, bool[] memory roles) internal {
        if (admins.length != roles.length) revert Invalid_Input_Length();
        for (uint256 i; i < admins.length; ++i) {
            pressAdmins[press][admins[i]] = roles[i];
        }
        emit SetAccountRoles({
            press: press,
            accounts: accounts,
            roles: roles
        });
    }

    function generate

    // /// @notice Initializes setup data in logic contract
    // function initializeWithData(bytes memory data) external;

    // function transmitRequest(address sender, bytes32[] memory merkleProof, uint256 quantity) external payable returns (bool);
}