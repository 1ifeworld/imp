// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {NodeRegistry} from "../src/NodeRegistry.sol";

contract NodeRegistryTest is Test {       

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////   

    address constant MOCK_USER_ACCOUNT = address(0x123);
    bytes constant ZERO_BYTES = new bytes(0);

    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////   

    NodeRegistry nodeRegistry;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test to clear 0 -> 1 gas costs for counter storage
    // function setUp() public {
    //     nodeRegistry = new NodeRegistry();  
    //     nodeRegistry.registerSchema(new bytes(0));
    //     nodeRegistry.initializeNode(new bytes(0));
    //     nodeRegistry.updateNode(new bytes(0));
    // }    
    

    //////////////////////////////////////////////////
    // INITIALIZE NODE TESTS
    //////////////////////////////////////////////////     

    // function test_initializeNode() public {
    //     uint256 expectedCount = nodeRegistry.nodeCount() + 1;
    //     vm.startPrank(MOCK_USER_ACCOUNT);
    //     // Checks if topics 1, 2, 3, non-indexed data and event emitter match expected emitter + event signature + event values
    //     vm.expectEmit(true, true, false, true, address(nodeRegistry));      
    //     // Emit event we are expecting
    //     emit NodeRegistry.InitializeNode(MOCK_USER_ACCOUNT, expectedCount, ZERO_BYTES);        
    //     // Perform call to emit event
    //     nodeRegistry.initializeNode(ZERO_BYTES);
    //     require(nodeRegistry.nodeCount() == expectedCount, "nodeCount not incremented correctly");
    // }    

    // function test_batchInitializeNode() public {
    //     uint256 quantity = 10;
    //     uint256 expectedCount = nodeRegistry.nodeCount() + quantity;
    //     vm.prank(MOCK_USER_ACCOUNT);
    //     nodeRegistry.initializeNodeBatch(generateEmptyData(quantity));
    //     require(nodeRegistry.nodeCount() == expectedCount, "nodeCount not incremented correctly");
    // }        

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  

    // function generateEmptyData(uint256 quantity) public pure returns (bytes[] memory batchData) {                   
    //     batchData = new bytes[](quantity);
    //     for (uint256 i; i < quantity; ++i) {
    //         batchData[i] = new bytes(0);
    //     }
    // }                   
}