// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {NodeRegistry} from "../src/core/NodeRegistry.sol";

/*
    NOTE:
    MISSING nodeSchemaRegistration tests
*/

contract NodeRegistryTest is Test {
    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    event RegisterNodeSchema(address indexed sender, uint256 indexed id, bytes32 indexed nodeSchema, bytes data);
    event RegisterNode(address sender, uint256 indexed id, uint256 indexed nodeId, bytes32 indexed nodeSchema, bytes data);
    event Message(address sender, uint256 indexed id, uint256 indexed nodeId, uint256 indexed messageId, bytes data);        

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

    NodeRegistry nodeRegistry;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test
    function setUp() public {
        nodeRegistry = new NodeRegistry();  
        nodeRegistry.registerNodeSchema(mockUserId, new bytes(0));
        nodeRegistry.registerNode(mockUserId, mockNodeSchema, new bytes(0));
        nodeRegistry.messageNode(mockUserId, mockNodeId, new bytes(0));
    }    

    //////////////////////////////////////////////////
    // REGISTER NODE TESTS
    ////////////////////////////////////////////////// 

    /*
        NODE REGISTRATION TESTS
        - test_registerNode
        - test_batchRegisterNode
        - test_initialData_RegisterNode
        - test_initialData_batchRegisterNode
    */

    /*
        Gas breakdown
        - first node registration (in setup, no data, cold access, zero -> non-zero messageCount) = 25,693
        - second node registration (no data, cold access, non-zero -> non-zero messageCount) = 8,593
        - third node registration (no data, warm access, non-zero -> non-zero messageCount) = 3,793
    */
    function test_registerNode() public {
        vm.startPrank(mockUserAccount);
        // Checks if topics 1, 2, 3, non-indexed data and event emitter match expected emitter + event signature + event values
        vm.expectEmit(true, true, true, true, address(nodeRegistry));        
        // Emit event we are expecting
        emit NodeRegistry.RegisterNode(mockUserAccount, mockUserId, 2, mockNodeSchema, zeroBytes);
        // Perform call to emit event
        nodeRegistry.registerNode(mockUserId, mockNodeSchema, zeroBytes);
        // Perform another call to test gas for second register node call in same txn
        nodeRegistry.registerNode(mockUserId, mockNodeSchema, zeroBytes);
        require(nodeRegistry.nodeCount() == 3, "nodeCount not incremented correctly");
    }    

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ empty data for each = 43.04k
    */
    function test_batchRegisterNode() public {
        vm.prank(mockUserAccount);
        uint256 quantity = 10;
        nodeRegistry.registerNodeBatch(mockUserId, generateNodeSchemas(quantity), generateEmptyData(quantity));
        require(nodeRegistry.nodeCount() == 11, "nodeCount not incremented correctly");
    }        

    /*
        Gas breakdown
        - first node registration (in setup, no data) = 25,693
        - second node registration (mock data) = 9,641
    */
    function test_initialData_RegisterNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.registerNode(mockUserId, mockNodeSchema, generateRegisterData());
        require(nodeRegistry.nodeCount() == 2, "nodeCount not incremented correctly");
    }        

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ mock data for each = 53.4k
    */
    function test_initialData_batchRegisterNode() public {
        vm.prank(mockUserAccount);
        uint256 quantity = 10;
        nodeRegistry.registerNodeBatch(mockUserId, generateNodeSchemas(quantity), generateBatchRegisterData(quantity));
        require(nodeRegistry.nodeCount() == 11, "nodeCount not incremented correctly");
    }     

    //////////////////////////////////////////////////
    // MESSAGE NODE TESTS
    ////////////////////////////////////////////////// 

    /*
        NODE MESSAGING TESTS
        - test_messageNode
        - test_batchMessageNode
        - test_publicationData_messageNode
        - test_publicationData_batchMessageNode
        - test_pointerData_messageNodea
        - test_pointerData_batchMessageNode
    */

    /*
        Gas breakdown
        - first message (in setup, no data, cold access, zero -> non-zero messageCount) = 24.79k 24795
        - second message (no data, cold access, non-zero -> non-zero messageCount) = 7,695
        - third message (no data, warm access, non-zero -> non-zero messageCount) = 2,895
    */
    // function test_messageNode() public {
    //     vm.prank(mockUserAccount);
    //     nodeRegistry.messageNode(new bytes(0));
    //     nodeRegistry.messageNode(new bytes(0));
    //     require(nodeRegistry.messageCount() == 3, "messageCount not incremented correctly");
    // }  

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ empty data for each = 32.7k
    */
    // function test_batchMessageNode() public {
    //     vm.prank(mockUserAccount);
    //     nodeRegistry.messageNodeBatch(generateEmptyData(10));
    //     require(nodeRegistry.messageCount() == 11, "messageCount not incremented correctly");
    // }    

    /*
        Gas breakdown
        - first message (in setup, no data) = 24.79k
        - second message (mock data) = 9,791
    */
    // function test_publicationData_messageNode() public {
    //     vm.prank(mockUserAccount);
    //     nodeRegistry.messageNode(generateMessageData());
    //     require(nodeRegistry.messageCount() == 2, "messageCount not incremented correctly");
    // }          

    /*
        Gas breakdown
        - 10 non-zero -> non-zero messages w/ mock pub uri data for each = 53,514
    */
    // function test_publicationData_batchMessageNode() public {
    //     vm.prank(mockUserAccount);
    //     nodeRegistry.messageNodeBatch(generateBatchMessageData(10));
    //     require(nodeRegistry.messageCount() == 11, "messageCount not incremented correctly");
    // }         
       
    /*
        Gas breakdown
        - first message (in setup, no data) = 24.79k
        - second message (mock pointer data) = 10,053
    */
    // function test_pointerData_messageNode() public {
    //     vm.prank(mockUserAccount);
    //     nodeRegistry.messageNode(generatePointerMessageData());
    //     require(nodeRegistry.messageCount() == 2, "messageCount not incremented correctly");
    // }      

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  

    function generateRegisterData() public view returns (bytes memory registerData) {
        address[] memory mockInitialAdmins = new address[](1);
        mockInitialAdmins[0] = mockUserAccount;
        registerData = abi.encode(mockInitialAdmins, mockMerkleRoot);        
    }

    function generateBatchRegisterData(uint256 quantity) public view returns (bytes[] memory batchRegisterData) {         
        address[] memory mockInitialAdmins = new address[](1);
        mockInitialAdmins[0] = mockUserAccount;                
        batchRegisterData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchRegisterData[i] = abi.encode(mockInitialAdmins, mockMerkleRoot);
        }
    }    

    function generateMessageData() public view returns (bytes memory messageData) {
        messageData = abi.encode(mockUri);        
    }        
    
    function generateBatchMessageData(uint256 quantity) public view returns (bytes[] memory batchMessageData) {         
        batchMessageData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchMessageData[i] = abi.encode(mockUserId, mockNodeId, mockNodeSchema, mockUri);
        }
    }

    function generateEmptyData(uint256 quantity) public pure returns (bytes[] memory batchData) {                   
        batchData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchData[i] = new bytes(0);
        }
    }          

    function generateNodeSchemas(uint256 quantity) public view returns (bytes32[] memory batchNodeSchemas) {                   
        batchNodeSchemas = new bytes32[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchNodeSchemas[i] = mockNodeSchema;
        }
    }             

    struct Pointer {
        uint256 chainId;
        uint256 tokenId;
        address target;
        bool hasTokenId;
    }    

    function generatePointerArray() public pure returns (Pointer[] memory pointers) {
        pointers = new Pointer[](1);
        pointers[0] = Pointer({
            chainId: 10,
            tokenId: 1000229,
            target: address(0x923842384),
            hasTokenId: true
        });        
    }    

    function generatePointerMessageData() public pure returns (bytes memory messageData) {
        messageData = abi.encode(generatePointerArray());        
    }         
}