// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {NodeRegistry} from "../src/core/NodeRegistry.sol";

contract NodeRegistryTest is Test {
    /* Constants */
    address mockUserAccount = address(0x123);
    uint256 mockUserId = 1;
    uint256 mockNodeId = 1;    
    uint256 mockSchemaId = 1;
    string mockUri = "ipfs://bafybeihax3e3suai6qrnjrgletfaqfzriziokl7zozrq3nh42df7u74jyu";
    bytes32 mockMerkleRoot = 0x86c29b38b8e59d3d08913796a5f1eeaefa01125ee2a61fdfd3aeffdcfe6180e1;
    
    /* NodeRegistry architecture */
    NodeRegistry nodeRegistry;

    // Set-up called before each test
    function setUp() public {
        nodeRegistry = new NodeRegistry();  
        nodeRegistry.registerNode(new bytes(0));
        nodeRegistry.messageNode(new bytes(0));
    }    

    /*
        NODE REGISTRATION TESTS
        - test_registerNode
        - test_batchRegisterNode
        - test_initialData_RegisterNode
        - test_initialData_batchRegisterNode
    */

    /*
        Gas breakdown
        - first node registration (in setup, no data, cold access, zero -> non-zero messageCount) = 24.861 24861
        - second node registration (no data, cold access, non-zero -> non-zero messageCount) = 7,761 (adding a return variable increases this to 7,798)
        - third node registration (no data, warm access, non-zero -> non-zero messageCount) = 2.96k
    */
    function test_registerNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.registerNode(new bytes(0));
        nodeRegistry.registerNode(new bytes(0));
        require(nodeRegistry.nodeCount() == 3, "nodeCount not incremented correctly");
    }    

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ empty data for each = 32.7k
    */
    function test_batchRegisterNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.registerNodeBatch(generateEmptyData(10));
        require(nodeRegistry.nodeCount() == 11, "nodeCount not incremented correctly");
    }        

    /*
        Gas breakdown
        - first node registration (in setup, no data) = 24.79k
        - second node registration (mock data) = 9,333
    */
    function test_initialData_RegisterNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.registerNode(generateRegisterData());
        require(nodeRegistry.nodeCount() == 2, "nodeCount not incremented correctly");
    }        

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ mock data for each = 48.3k
    */
    function test_initialData_batchRegisterNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.registerNodeBatch(generateBatchRegisterData(10));
        require(nodeRegistry.nodeCount() == 11, "nodeCount not incremented correctly");
    }     

    /*
        NODE MESSAGING TESTS
        - test_messageNode
        - test_batchMessageNode
        - test_publicationData_messageNode
        - test_publicationData_batchMessageNode
        - test_pointerData_messageNodea
    */

    /*
        Gas breakdown
        - first message (in setup, no data, cold access, zero -> non-zero messageCount) = 24.79k 24795
        - second message (no data, cold access, non-zero -> non-zero messageCount) = 7,695
        - third message (no data, warm access, non-zero -> non-zero messageCount) = 2,895
    */
    function test_messageNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.messageNode(new bytes(0));
        nodeRegistry.messageNode(new bytes(0));
        require(nodeRegistry.messageCount() == 3, "messageCount not incremented correctly");
    }  

    /*
        Gas breakdown
        - 10 non-zero -> non-zero registrations w/ empty data for each = 32.7k
    */
    function test_batchMessageNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.messageNodeBatch(generateEmptyData(10));
        require(nodeRegistry.messageCount() == 11, "messageCount not incremented correctly");
    }    

    /*
        Gas breakdown
        - first message (in setup, no data) = 24.79k
        - second message (mock data) = 9,791
    */
    function test_publicationData_messageNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.messageNode(generateMessageData());
        require(nodeRegistry.messageCount() == 2, "messageCount not incremented correctly");
    }          

    /*
        Gas breakdown
        - 10 non-zero -> non-zero messages w/ mock pub uri data for each = 53,514
    */
    function test_publicationData_batchMessageNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.messageNodeBatch(generateBatchMessageData(10));
        require(nodeRegistry.messageCount() == 11, "messageCount not incremented correctly");
    }         
       
    /*
        Gas breakdown
        - first message (in setup, no data) = 24.79k
        - second message (mock pointer data) = 10,053
    */
    function test_pointerData_messageNode() public {
        vm.prank(mockUserAccount);
        nodeRegistry.messageNode(generatePointerMessageData());
        require(nodeRegistry.messageCount() == 2, "messageCount not incremented correctly");
    }      

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  

    function generateRegisterData() public view returns (bytes memory registerData) {
        address[] memory mockInitialAdmins = new address[](1);
        mockInitialAdmins[0] = mockUserAccount;
        registerData = abi.encode(mockUserId, mockSchemaId, mockInitialAdmins, mockMerkleRoot);        
    }

    function generateBatchRegisterData(uint256 quantity) public view returns (bytes[] memory batchRegisterData) {         
        address[] memory mockInitialAdmins = new address[](1);
        mockInitialAdmins[0] = mockUserAccount;                
        batchRegisterData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchRegisterData[i] = abi.encode(mockUserId, mockSchemaId, mockInitialAdmins, mockMerkleRoot);
        }
    }    

    function generateMessageData() public view returns (bytes memory messageData) {
        messageData = abi.encode(mockUserId, mockNodeId, mockSchemaId, mockUri);        
    }        
    
    function generateBatchMessageData(uint256 quantity) public view returns (bytes[] memory batchMessageData) {         
        batchMessageData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchMessageData[i] = abi.encode(mockUserId, mockNodeId, mockSchemaId, mockUri);
        }
    }


    function generateEmptyData(uint256 quantity) public pure returns (bytes[] memory batchData) {                   
        batchData = new bytes[](quantity);
        for (uint256 i; i < quantity; ++i) {
            batchData[i] = new bytes(0);
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

    function generatePointerMessageData() public view returns (bytes memory messageData) {
        messageData = abi.encode(mockUserId, mockNodeId, mockSchemaId, generatePointerArray());        
    }         
}