// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {ChannelRegistry} from "../src/core/ChannelRegistry.sol";


contract ChannelRegistryTest is Test {
    /* Channel architecture */
    ChannelRegistry channelRegistry;
    address admin = address(0x123);
    address mockRouter = address(0x555); 

    // Set up called before each test
    function setUp() public {
        vm.startPrank(admin);
        channelRegistry = new ChannelRegistry(mockRouter);   
        vm.stopPrank();
    }    

    function test_newChannel() public {
        // setup new channel inputs
        string memory channelUri = "ipfs://bafybeidw4rmzno2ovlppggmhoal3tvuzi2ufbtaudyc37jqnj5pm5fyble/1"; 
        bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
        address[] memory admins = new address[](1);
        admins[0] = admin;

        bytes memory encodedData = abi.encode(channelUri, merkleRoot, admins);

        vm.startPrank(admin);
        channelRegistry.newChannel(encodedData);      
        require(channelRegistry.channelCounter() == 1, "counter not incremented correctly");
    }

    function test_addListing_writeToChannel() public {
        // setup new channel inputs
        string memory channelUri = "ipfs://bafybeidw4rmzno2ovlppggmhoal3tvuzi2ufbtaudyc37jqnj5pm5fyble/1"; 
        bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
        address[] memory admins = new address[](1);
        admins[0] = admin;
        bytes memory encodedData = abi.encode(channelUri, merkleRoot, admins);
        vm.startPrank(admin);
        channelRegistry.newChannel(encodedData);      


        // setup encoded listings
        ChannelRegistry.Listing[] memory listings = new ChannelRegistry.Listing[](1);
        listings[0] = ChannelRegistry.Listing({
            chainId: 10,
            tokenId: 100,
            pointer: address(0x123456678),
            hasTokenId: 0
        });
        bytes memory encodedListings = abi.encode(listings);
        // setup encoded data for writeToChannel
        uint256 channelId = 1;
        uint256 actionId = 20;
        bytes memory encodedWriteToChannelData = abi.encode(channelId, actionId, encodedListings);
        channelRegistry.writeToChannel(encodedWriteToChannelData);

        // require(channelRegistry.channelCounter() == 1, "counter not incremented correctly");
    }    
}