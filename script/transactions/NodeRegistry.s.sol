// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {NodeRegistry} from "../../src/core/NodeRegistry.sol";
import {INodeRegistryTypes} from "../utils/INodeRegistryTypes.sol";

contract NodeRegistryScript is INodeRegistryTypes, Script {

    NodeRegistry nodeRegistry;
    
    function setUp() public {
        
        // NOTE: replace address of NodeRegistry with one you want to target
        nodeRegistry = NodeRegistry(0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE);
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        
        fullCycle();

        // registerNode(1, keccak256(bytes("hi")), 1, new bytes(0));

        vm.stopBroadcast();
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////

    function registerSchema(uint256 userId, uint256 regType, bytes memory regBody) public returns (bytes32 schema) {
        SchemaRegistration memory schemaRegistration = SchemaRegistration({
            userId: userId, 
            regType: regType,
            regBody: regBody
        });        
        schema = nodeRegistry.registerSchema(abi.encode(schemaRegistration));
    }

    function registerNode(uint256 userId, bytes32 schema, uint256 regType, bytes memory regBody) public returns (uint256 nodeId) {
        NodeRegistration memory nodeRegistration = NodeRegistration({
            userId: userId, 
            schema: schema, 
            regType: regType,
            regBody: regBody
        });                 
        nodeRegistry.registerNode(abi.encode(nodeRegistration));
    }

    function messageNode(uint256 userId, uint256 nodeId, uint256 msgType, bytes memory msgBody) public {
        NodeMessage memory nodeMessage = NodeMessage({
            userId: userId, 
            nodeId: nodeId, 
            msgType: msgType,
            msgBody: msgBody
        });               
    }

    function fullCycle() public {
        uint256 userId = 1;
        bytes32 schema = registerSchema(userId, 0, new bytes(0));
        uint256 nodeId = registerNode(userId, schema, 0, new bytes(0));
        messageNode(userId, nodeId, 0, new bytes(0));
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/transactions/NodeRegistry.s.sol:NodeRegistryScript -vvvv --broadcast --fork-url http://localhost:8545