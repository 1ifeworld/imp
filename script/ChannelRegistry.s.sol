// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


import {Router} from "../src/core/router/Router.sol";
import {ChannelRegistry} from "../src/core/targets/channels/ChannelRegistry.sol";
import {IChannelRegistry} from "../src/core/targets/channels/interfaces/IChannelRegistry.sol";
import {IListing} from "../src/core/targets/channels/interfaces/IListing.sol";

contract DeployCore is Script {

    Router router;
    ChannelRegistry channelRegistry;
    ChannelRegistry channelRegistry2;
    address feeRecipient;
    uint256 fee;
    address constant admin = 0x33F59bfD58c16dEfB93612De65A5123F982F58bA;
    // NOTE: following merkle gymnastics conducted via lanyard.org
    // Merkle root generated from address(0x123) and address(0x321)
    bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
    // Proof value (convert to array) for address(0x123) on the merkleRoot provided above
    bytes32 merkleProofForAdminAndRoot = 0x71ef4e3ac02bbfe589f919cd478796b80265f2fa8354195b4d85495ddb4fbc5f;    

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        feeRecipient = address(0x999);
        fee = 0.0005 ether;    

        router = new Router();
        channelRegistry = new ChannelRegistry(address(router), feeRecipient, fee);
        channelRegistry2 = new ChannelRegistry(address(router), feeRecipient, fee);
        
        // register transmitters + selecotrs on router
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = IChannelRegistry.newChannel.selector;
        selectors[1] = IChannelRegistry.addToChannel.selector;
        router.registerTarget(address(channelRegistry), selectors);
        router.registerTarget(address(channelRegistry2), selectors);

        // Creates one channel on two different channel registries through router
        createNewChannel(address(channelRegistry));
        createNewChannel(address(channelRegistry2));     
        // Add one listing to one channel through router
        callTarget_AddListing(address(channelRegistry));   
        // Add one listing to one channel to 2 different channel registries through router
        callTargetMulti_AddListing(address(channelRegistry), address(channelRegistry2));

        vm.stopBroadcast();
    }

    function createNewChannel(address target) public returns (address) {
        // setup initialAdmins array for admin init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // Setup channel inputs
        string memory uri = "ipfs://testing_testing";
        bytes memory initData = abi.encode(uri, merkleRoot, initialAdmins);
        // Setup router  inuts
        Router.CallInputs memory callInputs =
            Router.CallInputs({target: target, selector: IChannelRegistry.newChannel.selector, data: initData});
        // Call router
        router.callTarget(callInputs);
    }

    function callTarget_AddListing(address target) public {
        // setup empty merkle proof -- will only work if sender is admin on press
        bytes32[] memory emptyProof = new bytes32[](1);
        // setup listings array
        IListing.Listing[] memory listings = new IListing.Listing[](1);
        listings[0] = IListing.Listing({chainId: 10, tokenId: 13, listingAddress: address(0x888), hasTokenId: true});
        // setup encoded inputs for addToChannel function
        uint256 channelId = 1;
        bytes memory encodedData = abi.encode(channelId, emptyProof, listings);        
        // Setup router iputs
        Router.CallInputs memory callInputs = Router.CallInputs({
            target: address(target),
            selector: IChannelRegistry.addToChannel.selector,
            data: encodedData
        });
        // Call router - hardcoded value to fee x 1
        router.callTarget{value: fee}(callInputs);              
    }    

    function callTargetMulti_AddListing(address target1, address target2) public {
        // setup empty merkle proof -- will only work if sender is admin on press
        bytes32[] memory emptyProof = new bytes32[](1);
        // setup listings array
        IListing.Listing[] memory listings = new IListing.Listing[](1);
        listings[0] = IListing.Listing({chainId: 10, tokenId: 13, listingAddress: address(0x888), hasTokenId: true});
        // setup encoded inputs for addToChannel function
        uint256 channelId = 1;
        bytes memory encodedData = abi.encode(channelId, emptyProof, listings);                   
        // Setup router iputs
        Router.CallInputs[] memory callInputsArray = new Router.CallInputs[](2);
        callInputsArray[0] = Router.CallInputs({
            target: address(target1),
            selector: IChannelRegistry.addToChannel.selector,
            data: encodedData
        });
        callInputsArray[1] = Router.CallInputs({
            target: address(target2),
            selector: IChannelRegistry.addToChannel.selector,
            data: encodedData
        });
        // Setup router values for multi target
        uint256[] memory values = new uint256[](2);
        values[0] = fee; 
        values[1] = fee; 
        // Call router   
        router.callTargetMulti{value: (fee * 2)}(callInputsArray, values);        
    }        
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ChannelRegistry.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify
// forge script script/ChannelRegistry.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url {block exploerer verifier url}
// forge script script/ChannelRegistry.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-optimistic.etherscan.io/api

// optimism verifier url https://api-optimistic.etherscan.io/api