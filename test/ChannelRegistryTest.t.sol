// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {ChannelRegistry} from "../src/core/ChannelRegistry.sol";

contract ChannelRegistryTest is Test {
    /* ChannelRegistry architecture */
    ChannelRegistry channelRegistry;
    /* CONSTANTS */
    address admin = address(0x999);
    /* TYPES */
    struct Pointer {
        uint128 chainId;
        uint128 tokenId;
        address addr;
        bool hasTokenId;
    }

    // Set up called before each test
    function setUp() public {
        channelRegistry = new ChannelRegistry();  
    }    

    /*
    - channelId initialization data (bytes)
        - channelId initialization data is an encoded blob that contains the following contents
            - rid (uint256) to receieve provenance
            - accessSchema (uint256) to setup for channelId related actions
            - accesScehemaData (bytes) to setup for channelId related actions
                - schema specific data to decode and store in channel access schema store
                    - ex: abi.encode(address[] admins, bytes32 merkleRoot)
            - uri (string) ipfs pointer to channelUri json that contains the following:
                - name (string)
                - description (string)
                - cover image uri (string), which itself should be a pointer to decentralized file storage provider
    */
    function test_newChannel() public {
        // setup new channel inputs
        uint256 mockRid = 1920;
        uint256 mockAccessScehma = 110;
        string memory mockChannelUri = "ipfs://bafybeidw4rmzno2ovlppggmhoal3tvuzi2ufbtaudyc37jqnj5pm5fyble/1"; 
        address[] memory admins = new address[](1);
        admins[0] = admin;     
        bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
        bytes memory mockAccessSchemaData = abi.encode(admins, merkleRoot);
        // encode channel inputs
        bytes memory encodedNewChannelData = abi.encode(mockRid, mockAccessScehma, mockAccessSchemaData, mockChannelUri);        
        // create new channel
        channelRegistry.newChannel(encodedNewChannelData);     
    }  

    /*
        - Data is passed through channels by calling `submitChannelAction()` and the emission of `ChannelAction` events, which are encoded blobs of data with the follwing contents
            - rid (uint256) to receive provenance
            - channelId (uint256) to target
            - actionId (uint256) to target
            - data (bytes) to process
                - ex: abi.encode(Pointers[]);            
    */
    function test_addPointer_submitChannelAction() public {
        // setup channelAction inputs
        uint256 mockRid = 1234010;
        uint256 mockChannelId = 89020138491;
        uint256 mockActionId = 210;
        Pointer[] memory pointers = new Pointer[](1);
        pointers[0] = Pointer({
            chainId: 10,
            tokenId: 100,
            addr: address(0x123456678),
            hasTokenId: false
        });
        bytes memory encodedPointers = abi.encode(pointers);      
        // encode submit channel action  
        bytes memory encodedAction = abi.encode(mockRid, mockChannelId, mockActionId, encodedPointers);
        // call submitChannelAction
        channelRegistry.submitChannelAction(encodedAction);
    }    

    /* HELPERS */
}