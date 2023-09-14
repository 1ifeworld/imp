// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {Router} from "../src/core/router/Router.sol";

import {ChannelRegistry} from "../src/core/targets/channels/ChannelRegistry.sol";
import {IChannelRegistry} from "../src/core/targets/channels/interfaces/IChannelRegistry.sol";
import {IListing} from "../src/core/targets/channels/interfaces/IListing.sol";

import {ERC1155Registry} from "../src/core/targets/tokens/ERC1155Registry.sol";
import {IERC1155Registry} from "../src/core/targets/tokens/interfaces/IERC1155Registry.sol";
import {MockSalesModule} from "./mocks/MockSalesModule.sol";

contract StringStorage {
    uint256 public counter;
    mapping(uint256 => string) public stringInfo;
    function store(string memory uri) external {
        stringInfo[counter] = uri;
    }
}

contract RouterTest is Test {
    // PUBLIC TEST VARIABLES
    Router router;
    /* Channel architecture */
    ChannelRegistry channelRegistry;
    ChannelRegistry channelRegistry2;
    address feeRecipient = address(0x999);
    uint256 fee = 0.0005 ether;
    address admin = address(0x123);
    // NOTE: following merkle gymnastics conducted via lanyard.org
    // Merkle root generated from address(0x123) and address(0x321)
    bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
    // Proof value (convert to array) for address(0x123) on the merkleRoot provided above
    bytes32 merkleProofForAdminAndRoot = 0x71ef4e3ac02bbfe589f919cd478796b80265f2fa8354195b4d85495ddb4fbc5f;
    /* ERC1155 architecture */
    ERC1155Registry erc1155Registry;
    MockSalesModule mockSalesModule;

    // Set up called before each test
    function setUp() public {
        vm.startPrank(admin);
        // deploy router + channel registry + erc1155 registry
        router = new Router();
        channelRegistry = new ChannelRegistry(address(router), feeRecipient, fee);
        channelRegistry2 = new ChannelRegistry(address(router), feeRecipient, fee);
        erc1155Registry = new ERC1155Registry(address(router), feeRecipient, fee);
        mockSalesModule = new MockSalesModule();
        // register channel registry functions on router
        bytes4[] memory channelSelectors = new bytes4[](2);
        channelSelectors[0] = IChannelRegistry.newChannel.selector;
        channelSelectors[1] = IChannelRegistry.addToChannel.selector;
        router.registerTarget(address(channelRegistry), channelSelectors);
        router.registerTarget(address(channelRegistry2), channelSelectors);
        // register erc1155 registry functions on router     
        bytes4[] memory erc1155Selectors = new bytes4[](1);
        erc1155Selectors[0] = IERC1155Registry.createTokens.selector;
        router.registerTarget(address(erc1155Registry), erc1155Selectors);        
        vm.stopPrank();
    }    

    function test_newToken() public {
        // Setup createTokens data
        ERC1155Registry.TokenInputs[] memory tokenInputs = new ERC1155Registry.TokenInputs[](1);
        tokenInputs[0] = ERC1155Registry.TokenInputs({
            salesModule: address(0),
            uri: "ipfs://bafkreiden6msn3wycwto42hepsri2ztocoh3e36jl5mawvlem2xqkb7ffu",
            commands: new bytes(0)
        });
        bytes memory encodedData = abi.encode(admin, tokenInputs);
        // Setup Router inputs
        Router.CallInputs memory callInputs = Router.CallInputs({
            target: address(erc1155Registry),
            selector: IERC1155Registry.createTokens.selector,
            data: encodedData
        });        
        // setup fees + distribute eth
        vm.deal(admin, 1 ether);
        vm.prank(admin);        
        // Call router
        router.callTarget{value: fee}(callInputs);         
    }

    function test_10NewTokens() public {
        // Setup createTokens data
        uint256 numTokens = 10;
        ERC1155Registry.TokenInputs[] memory tokenInputs = generateTokenInputs(numTokens, address(0));
        bytes memory encodedData = abi.encode(admin, tokenInputs);
        // Setup Router inputs
        Router.CallInputs memory callInputs = Router.CallInputs({
            target: address(erc1155Registry),
            selector: IERC1155Registry.createTokens.selector,
            data: encodedData
        });        
        // setup fees + distribute eth
        vm.deal(admin, 1 ether);
        vm.prank(admin);        
        // Call router
        router.callTarget{value: fee * numTokens}(callInputs);         
    }    

    function test_newChannel() public returns (address) {
        // setup initialAdmins array for admin init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // Setup channel inputs
        string memory uri = "ipfs://testing_testing";
        bytes memory initData = abi.encode(uri, merkleRoot, initialAdmins);
        // Setup router  inuts
        Router.CallInputs memory callInputs = Router.CallInputs({
            target: address(channelRegistry),
            selector: IChannelRegistry.newChannel.selector,
            data: initData
        });
        // Call router
        router.callTarget(callInputs);
    }

    function test_callTarget() public {
        // Create new channel in channelRegistry
        createNewChannel(address(channelRegistry));
        // setup merkle proof for included address
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleProofForAdminAndRoot;
        // setup listings array
        IListing.Listing[] memory listings = new IListing.Listing[](1);
        listings[0] = IListing.Listing({chainId: 10, tokenId: 13, listingAddress: address(0x888), hasTokenId: true});
        // setup encoded inputs for addToChannel function
        uint256 channelId = 1;
        bytes memory encodedData = abi.encode(channelId, proof, listings);
        // setup fees + distribute eth
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        // Setup router iputs
        Router.CallInputs memory callInputs = Router.CallInputs({
            target: address(channelRegistry),
            selector: IChannelRegistry.addToChannel.selector,
            data: encodedData
        });
        // Call router - hardcoded value to fee x 1
        router.callTarget{value: fee}(callInputs);
        // checks
        require(admin.balance == 1 ether - fee, "fees not correct");
        require(feeRecipient.balance == fee, "fees not correcthg");
    }

    function test_multiCallTarget() public {
        // Initialize channel on channelRegistry tokenless press
        createNewChannel(address(channelRegistry));
        createNewChannel(address(channelRegistry2));
        // setup merkle proof for included address
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleProofForAdminAndRoot;
        // setup listings array
        IListing.Listing[] memory listings = new IListing.Listing[](1);
        listings[0] = IListing.Listing({chainId: 10, tokenId: 13, listingAddress: address(0x888), hasTokenId: true});
        // setup encoded inputs for addToChannel function
        uint256 channelId = 1;
        bytes memory encodedData = abi.encode(channelId, proof, listings);
        // setup fees + distribute eth
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        // Setup router iputs
        Router.CallInputs[] memory callInputsArray = new Router.CallInputs[](2);
        callInputsArray[0] = Router.CallInputs({
            target: address(channelRegistry),
            selector: IChannelRegistry.addToChannel.selector,
            data: encodedData
        });
        callInputsArray[1] = Router.CallInputs({
            target: address(channelRegistry2),
            selector: IChannelRegistry.addToChannel.selector,
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

    function generateTokenInputs(uint256 quantity, address salesModule) internal returns (ERC1155Registry.TokenInputs[] memory) {
        ERC1155Registry.TokenInputs[] memory tokenInputs = new ERC1155Registry.TokenInputs[](quantity);
        for (uint256 i; i < quantity; ++i) {
            tokenInputs[i] = ERC1155Registry.TokenInputs({
                salesModule: salesModule,
                uri: "ipfs://bafkreiden6msn3wycwto42hepsri2ztocoh3e36jl5mawvlem2xqkb7ffu",
                commands: new bytes(0)
            });
        }
        return tokenInputs;
    }

    function test_stringStorage() public {
        StringStorage sStorage = new StringStorage();
        string memory myString = "ipfs://bafkreiden6msn3wycwto42hepsri2ztocoh3e36jl5mawvlem2xqkb7ffu";
        bytes memory myStringEncoded = abi.encode(myString);
        bytes memory myStringBytes = bytes(myString);
        console2.log("how long is string encoded", myStringEncoded.length);
        console2.log("how long is string pure byte assignment", myStringBytes.length);
        sStorage.store(myString);
        require(keccak256(bytes(sStorage.stringInfo(0))) == keccak256(bytes(myString)), "incorrect storage");
    }    
}
