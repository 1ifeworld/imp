// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


import {RouterV2} from "../src/core/router/RouterV2.sol";
import {SharedListingTransmitter} from "../src/implementations/transmitter/listings/press/SharedListingTransmitter.sol";
import {IListing} from "../src/implementations/transmitter/listings/types/IListing.sol";
import {ISharedPress} from "../src/core/press/interfaces/ISharedPress.sol";

contract DeployCore is Script {

    RouterV2 router;
    SharedListingTransmitter transmitter;
    SharedListingTransmitter transmitter2;
    address feeRecipient;
    uint256 fee;
    address constant admin = 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170;
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

        router = new RouterV2();
        transmitter = new SharedListingTransmitter(address(router), feeRecipient, fee);
        transmitter2 = new SharedListingTransmitter(address(router), feeRecipient, fee);
        
        // register transmitters + selecotrs on router
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ISharedPress.initialize.selector;
        selectors[1] = ISharedPress.handleSendV2.selector;
        router.registerTarget(address(transmitter), selectors);
        router.registerTarget(address(transmitter2), selectors);

        // Iniitialize one channels on two different transmitters through router
        initializeChannel(address(transmitter));
        initializeChannel(address(transmitter2));     
        // Add one listing to one channel through router
        callTarget_AddListing(address(transmitter));   
        // Add one listing to one channel to 2 different transmitters through router
        callTargetMulti_AddListing(address(transmitter), address(transmitter2));

        vm.stopBroadcast();
    }

    function initializeChannel(address target) public { 
        // setup initialAdmins array for admin init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // Setup channel inputs
        string memory uri = "ipfs://testing_testing";
        bytes memory initData = abi.encode(uri, merkleRoot, initialAdmins);     
        // Setup router  inuts
        RouterV2.CallInputs memory callInputs = RouterV2.CallInputs({
            target: target,
            selector: ISharedPress.initialize.selector,
            data: initData
        });
        // Call router
        router.callTarget(callInputs);
    }        

    function callTarget_AddListing(address target) public {
        // setup empty merkle proof -- will only work if sender is admin on press
        bytes32[] memory emptyProof = new bytes32[](1);
        // setup listings array
        IListing.Listing[] memory listings = new IListing.Listing[](1);
        listings[0] = IListing.Listing({
            chainId: 7777777,
            tokenId: 17,
            listingAddress: address(0x7777777),
            hasTokenId: true
        });
        // setup encoded inputs for sendDataV2 function
        uint256 channelIdTarget = 1;
        bytes memory encodedData = abi.encode(channelIdTarget, emptyProof, listings);        
        // Setup router iputs
        RouterV2.CallInputs memory callInputs = RouterV2.CallInputs({
            target: address(target),
            selector: ISharedPress.handleSendV2.selector,
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
        listings[0] = IListing.Listing({
            chainId: 7777777,
            tokenId: 17,
            listingAddress: address(0x7777777),
            hasTokenId: true
        });
        // setup encoded inputs for sendDataV2 function
        uint256 channelIdTarget = 1;
        bytes memory encodedData = abi.encode(channelIdTarget, emptyProof, listings);           
        // Setup router iputs
        RouterV2.CallInputs[] memory callInputsArray = new RouterV2.CallInputs[](2);
        callInputsArray[0] = RouterV2.CallInputs({
            target: address(target1),
            selector: ISharedPress.handleSendV2.selector,
            data: encodedData
        });
        callInputsArray[1] = RouterV2.CallInputs({
            target: address(target2),
            selector: ISharedPress.handleSendV2.selector,
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
// forge script script/RouterV2_And_Transmitter.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify
// forge script script/RouterV2_And_Transmitter.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url {block exploerer verifier url}
// forge script script/RouterV2_And_Transmitter.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-optimistic.etherscan.io/api

// optimism goerli verifier url https://api-optimistic.etherscan.io/api