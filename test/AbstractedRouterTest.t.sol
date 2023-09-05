// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {RouterV2} from "../src/core/router/RouterV2.sol";
import {SharedListingTransmitter} from "../src/implementations/transmitter/listings/press/SharedListingTransmitter.sol";
import {ISharedPress} from "../src/core/press/interfaces/ISharedPress.sol";
import {IListing} from "../src/implementations/transmitter/listings/types/IListing.sol";

contract AbstractedRouterTest is Test {
 
    // PUBLIC TEST VARIABLES
    RouterV2 router;
    SharedListingTransmitter sharedPress;
    SharedListingTransmitter sharedPress2;
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
        // deploy router + shared press
        router = new RouterV2();
        sharedPress = new SharedListingTransmitter(address(router), feeRecipient, fee);
        sharedPress2 = new SharedListingTransmitter(address(router), feeRecipient, fee);
        // register sharesPress functions on router
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ISharedPress.initialize.selector;
        selectors[1] = ISharedPress.handleSendV2.selector;
        router.registerTarget(address(sharedPress), selectors);
        router.registerTarget(address(sharedPress2), selectors);
    }  

    function test_initialize() public returns (address) { 
        // setup initialAdmins array for admin init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // Setup channel inputs
        string memory uri = "ipfs://testing_testing";
        bytes memory initData = abi.encode(uri, merkleRoot, initialAdmins);     
        // Setup router  inuts
        RouterV2.CallInputs memory callInputs = RouterV2.CallInputs({
            target: address(sharedPress),
            selector: ISharedPress.initialize.selector,
            data: initData
        });
        // Call router
        router.callTarget(callInputs);
    }           

    function test_callTarget() public {
        // Initialize channel on sharedPress tokenless press
        initializeChannel(address(sharedPress));
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
        // Setup router iputs
        RouterV2.CallInputs memory callInputs = RouterV2.CallInputs({
            target: address(sharedPress),
            selector: ISharedPress.handleSendV2.selector,
            data: encodedData
        });
        // Call router - hardcoded value to fee x 1
        router.callTarget{value: fee}(callInputs);      
        // checks
        require(admin.balance == 1 ether - fee, "fees not correct");
        require(feeRecipient.balance == fee, "fees not correcthg");        
    }

    function test_callTargetMulti() public {
        // Initialize channel on sharedPress tokenless press
        initializeChannel(address(sharedPress));
        initializeChannel(address(sharedPress2));
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
        vm.startPrank(admin);        
        // Setup router iputs
        RouterV2.CallInputs[] memory callInputsArray = new RouterV2.CallInputs[](2);
        callInputsArray[0] = RouterV2.CallInputs({
            target: address(sharedPress),
            selector: ISharedPress.handleSendV2.selector,
            data: encodedData
        });
        callInputsArray[1] = RouterV2.CallInputs({
            target: address(sharedPress2),
            selector: ISharedPress.handleSendV2.selector,
            data: encodedData
        });
        // Setup router values for multi target
        uint256[] memory values = new uint256[](2);
        values[0] = 0.0005 ether; 
        values[1] = 0.0005 ether; 
        // Call router   
        router.callTargetMulti{value: (fee * 2)}(callInputsArray, values);      
        // checks
        require(admin.balance == 1 ether - (fee * 2), "fees not correct");
        require(feeRecipient.balance == (fee * 2), "fees not correcthg");        
    }    

    /* HELPERS */

    function initializeChannel(address target) public returns (address) { 
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
}