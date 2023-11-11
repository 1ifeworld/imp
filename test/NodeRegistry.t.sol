// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {NodeRegistry} from "../src/NodeRegistry.sol";

contract NodeRegistryTest is Test {       

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////   

    address constant MOCK_USER = address(0x123);
    bytes constant ZERO_BYTES = new bytes(0);
    bytes32 constant ZERO_BYTES32 = keccak256(new bytes(0));
    bytes32 constant PUB_SCHEMA = 0xF36F2F0432F99EA34A360F154CEA9D1FAD45C7319E27ADED55CC0D28D0924068;
    bytes32 constant CHANNEL_SCHEMA = 0x08B83A3AFF9950D7F88522AC4A172BD8405BE30B0D3B416D42FD73C30AC27C9F;
    bytes constant ipfsEx = abi.encode("ipfs/bafybeiczsscdsbs7ffqz55asqdf3smv6klcw3gofszvwlyarci47bgf354");

    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////   

    NodeRegistry nodeRegistry;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test to clear 0 -> 1 gas costs for counter storage
    function setUp() public {
        nodeRegistry = new NodeRegistry();  
        bytes[] memory array = new bytes[](1);
        array[0] = ZERO_BYTES;
        nodeRegistry.register(ZERO_BYTES32, array);
    }    
    
    //////////////////////////////////////////////////
    // INITIALIZE NODE TESTS
    //////////////////////////////////////////////////     

    function test_register() public {
        // Prep input data
        bytes[] memory messages = new bytes[](2);
        uint256[] memory members = new uint256[](2);
        members[0] = 2;
        members[1] = 3;

        messages[0] = abi.encode(
            1,
            101,
            abi.encode(1, members)
        );

        messages[1] = abi.encode(
            1,
            201,
            abi.encode("yourIpfsStringHere")
        );

        uint256 expectedCount = nodeRegistry.nodeCount() + 1;
        vm.prank(MOCK_USER);        
        // Checks if topics 1, 2, 3, non-indexed data and event emitter match expected emitter + event signature + event values
        vm.expectEmit(true, true, true, true, address(nodeRegistry));    
        // Emit event with expected value
        emit NodeRegistry.Register(MOCK_USER, PUB_SCHEMA, expectedCount, messages);        
        // Call `register()` on nodeRegistry
        nodeRegistry.register(PUB_SCHEMA, messages);
        // Check storage updated correctly
        assertEq(nodeRegistry.nodeCount(), expectedCount);
    }        

    // function test_batch() public {
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