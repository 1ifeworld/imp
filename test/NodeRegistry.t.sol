// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {NodeRegistry} from "../src/core/NodeRegistry.sol";

contract NodeRegistryTest is Test {
    /* CONSTANTS */
    address user = address(0x444);
    uint256 mockNodeId = 1;    
    /* NodeRegistry architecture */
    NodeRegistry nodeRegistry;

    // Set up called before each test
    function setUp() public {
        nodeRegistry = new NodeRegistry();  
        nodeRegistry.registerNode(new bytes(0));
        nodeRegistry.messageNodeWithIdSpecificNonce(mockNodeId, generateMockMessageDataWithNonce());
        nodeRegistry.messageNodeWithGenericNonce(generateMockMessageData());
    }    
    /*
        Gas breakdown
        - first node registration (in setup, mock data) = 25.00k
        - second node registration (no data) = 9.62k
        - third node registration (mock data) = 4.85k
    */
    function test_registerNodes() public {
        vm.prank(user);
        nodeRegistry.registerNode(generateMockRegistrationData());
        nodeRegistry.registerNode(generateMockRegistrationData());
        require(nodeRegistry.nodeCount() == 3, "nodeCount not incremented correctly");
    }    

    /*
        Gas breakdown (no-nonce version so cost always the same)
        - abi.encode(userId, nodeId, schemaId, Pointers[]) = 5.5k
    */
    function test_messageNode() public {
        vm.prank(user);
        nodeRegistry.messageNode(generateMockMessageData());        
    }

    /*
        Gas breakdown
        - first message (in setup, zero => non zero write)
            - abi.encode(userId, schemaId, Pointers[]) = 28.21k
        - second message (post setup, cold access, non zero => non zero write)
            - abi.encode(userId, schemaId, Pointers[]) = 11.11k      
        - third message (post setup, warm access, non zero => non zero write)
            - abi.encode(userId, schemaId, Pointers[]) = 6.31k                
    */    
    function test_idSpecificNonceBasedMessageNode() public {
        vm.prank(user);
        uint256 mockUserId = 1;
        uint256 mockSchemaId = 1;        
        nodeRegistry.messageNodeWithIdSpecificNonce(
            mockNodeId, 
            abi.encode(mockUserId, mockSchemaId, generatePointerArray())
        );        
        nodeRegistry.messageNodeWithIdSpecificNonce(
            mockNodeId, 
            abi.encode(mockUserId, mockSchemaId, generatePointerArray())
        );                             
    }    

    /*
        Gas breakdown
        - first message (in setup, zero => non zero write)
            - abi.encode(userId, nodeId, schemaId, Pointers[]) = 28.08k
        - second message (post setup, cold access, non zero => non zero write)
            - abi.encode(userId, nodeId, schemaId, Pointers[]) = 10.98k      
        - third message (post setup, warm access, non zero => non zero write)
            - abi.encode(userId, nodeId, schemaId, Pointers[]) = 6.180k                
    */    
    function test_genericNonceBasedMessageNode() public {
        vm.prank(user);     
        nodeRegistry.messageNodeWithGenericNonce(generateMockMessageData());        
        nodeRegistry.messageNodeWithGenericNonce(generateMockMessageData());                                
    }       

    /*
        Gas breakdown
        - 100 messages (in setup, zero => non zero write)
            - abi.encode(userId, nodeId, schemaId, ipfsUri) = 588.96k
        *** rough cost of emitting same uri data in 100 unique 1155 tokens 10,000,000 gas
    */
    function test_genericNonceBasedv1BatchMessageNode() public {
        vm.prank(user);     
        nodeRegistry.batchMessageNodeWithGenericNonce_v1(generate100BatchMessageData());                                
    }      

    /*
        Gas breakdown
        - 100 messages (in setup, zero => non zero write)
            - abi.encode(userId, nodeId, schemaId, ipfsUri) = 411.54k gas
        *** rough cost of emitting same uri data in 100 unique 1155 tokens 10,000,000 gas
    */
    function test_genericNonceBasedv2BatchMessageNode() public {
        vm.prank(user);     
        nodeRegistry.batchMessageNodeWithGenericNonce_v2(generate100BatchMessageData());                                
    }         

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  

    struct Pointer {
        uint256 chainId;
        uint256 tokenId;
        address target;
        bool hasTokenId;
    }

    function generateMockRegistrationData() public returns (bytes memory mockRegistrationData) {
        uint256 mockUserId = 1;
        address[] memory mockInitialAdmins = new address[](1);
        mockInitialAdmins[0] = address(0x124);
        bytes32 mockMerkleRoot = 0x86c29b38b8e59d3d08913796a5f1eeaefa01125ee2a61fdfd3aeffdcfe6180e1;
        mockRegistrationData = abi.encode(mockUserId, mockInitialAdmins, mockMerkleRoot);        
    }

    function generatePointerArray() public returns (Pointer[] memory pointers) {
        pointers = new Pointer[](1);
        pointers[0] = Pointer({
            chainId: 10,
            tokenId: 1000229,
            target: address(0x923842384),
            hasTokenId: true
        });        
    }

    function generateMockMessageData() public returns (bytes memory mockMessageData) {
        uint256 mockUserId = 1;
        uint256 mockNodeId = 1;
        uint256 mockSchemaId = 1;
        mockMessageData = abi.encode(mockUserId, mockNodeId, mockSchemaId, generatePointerArray());        
    }    

    function generateMockMessageDataWithNonce() public returns (bytes memory mockMessageData) {
        uint256 mockUserId = 1;
        uint256 mockSchemaId = 1;
        mockMessageData = abi.encode(mockUserId, mockSchemaId, generatePointerArray());        
    }       

    function generate100BatchMessageData() public returns (bytes[] memory mockBatchMessageData) {
        uint256 mockUserId = 1;
        uint256 mockNodeId = 1;
        uint256 mockSchemaId = 1;        
        string memory mockUri = "ipfs://bafybeihax3e3suai6qrnjrgletfaqfzriziokl7zozrq3nh42df7u74jyu";
        mockBatchMessageData = new bytes[](100);
        for (uint256 i; i < 100; ++i) {
            mockBatchMessageData[i] = abi.encode(mockUserId, mockNodeId, mockSchemaId, mockUri);
        }
    }
}