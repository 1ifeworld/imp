// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {Router} from "../src/core/router/Router.sol";
import {SharedListingTransmitter} from "../src/implementations/transmitter/listings/press/SharedListingTransmitter.sol";
import {ISharedPress} from "../src/core/press/interfaces/ISharedPress.sol";
import {IListing} from "../src/implementations/transmitter/listings/types/IListing.sol";

contract SharedPressTest is Test {
 
    // PUBLIC TEST VARIABLES
    Router router;
    SharedListingTransmitter sharedPress;
    address feeRecipient = address(0x999);
    uint256 fee = 0.0005 ether;    
    address admin = address(0x123);
    // NOTE: following merkle gymnastics conducted via lanyard.org
    // Merkle root generated from address(0x123) and address(0x321)
    bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
    // Proof value (convert to array) for address(0x123) on the merkleRoot provided above
    bytes32 merkleProofForAdminAndRoot = 0x71ef4e3ac02bbfe589f919cd478796b80265f2fa8354195b4d85495ddb4fbc5f;

    // Set up called before each test
    function setUp() public {
        router = new Router();
        sharedPress = new SharedListingTransmitter(address(router), feeRecipient, fee);
    }  

    function test_sendData() public {
        // Initialize channel on sharedPress tokenless press
        initializeChannel();
        // setup merkle proof for included address
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleProofForAdminAndRoot;
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
        bytes memory encodedData = abi.encode(channelIdTarget, proof, listings);
        // setup fees + distribute eth
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        // hardcoded value to fee x 1
        router.sendDataV2{value: fee}(address(sharedPress), encodedData);        
        // checks
        require(admin.balance == 1 ether - fee, "fees not correct");
        require(feeRecipient.balance == fee, "fees not correcthg");        
    }

    function initializeChannel() public returns (address) { 
        // setup initialAdmins array for admin init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // Setup channel inputs
        string memory uri = "ipfs://testing_testing";
        bytes memory initData = abi.encode(uri, merkleRoot, initialAdmins);     
        // call router
        router.setupPressV2(address(sharedPress), initData);
    }    
}