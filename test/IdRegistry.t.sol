// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {IdRegistry} from "../src/core/IdRegistry.sol";

// import {EntryPoint} from "light-account/lib/account-abstraction/contracts/core/EntryPoint.sol";
// import {LightAccount} from "light-account/src/LightAccount.sol";
// import {LightAccountFactory} from "light-account/src/LightAccountFactory.sol";

contract IdRegistryTest is Test {       

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////   

    address mockUserAccount = address(0x123);
    uint256 mockUserId = 1;
    uint256 mockNodeId = 1;    
    bytes32 mockNodeSchema = keccak256(abi.encode(1));
    string mockUri = "ipfs://bafybeihax3e3suai6qrnjrgletfaqfzriziokl7zozrq3nh42df7u74jyu";
    bytes32 mockMerkleRoot = 0x86c29b38b8e59d3d08913796a5f1eeaefa01125ee2a61fdfd3aeffdcfe6180e1;
    bytes zeroBytes = new bytes(0);

    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////   

    /* IMP infra */
    IdRegistry public idRegistry;

    /* Smart account infra */
    // EntryPoint public entryPoint;
    // LightAccount public account;
    // LightAccount public contractOwnedAccount;
    // uint256 public salt = 1;


    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test
    function setUp() public {
        // entryPoint = new EntryPoint();
        // LightAccountFactory factory = new LightAccountFactory(entryPoint);
        // account = factory.createAccount(eoaAddress, salt);
    }    

    //////////////////////////////////////////////////
    // REGISTER NODE TESTS
    ////////////////////////////////////////////////// 

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  
}