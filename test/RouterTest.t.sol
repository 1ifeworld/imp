// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {Router} from "../src/core/router/Router.sol";
import {FactoryTransmitterListings} from "../src/implementations/transmitter/listings/factory/FactoryTransmitterListings.sol";
import {IFactory} from "../src/core/factory/interfaces/IFactory.sol";
import {PressTransmitterListings} from "../src/implementations/transmitter/listings/press/PressTransmitterListings.sol";
import {PressProxy} from "../src/core/press/proxy/PressProxy.sol";
import {IPress} from "../src/core/press/interfaces/IPress.sol";
import {IPressTypesV1} from "../src/core/press/types/IPressTypesV1.sol";
import {IListing} from "../src/implementations/transmitter/listings/types/IListing.sol";
import {LogicTransmitterMerkleAdmin} from "../src/implementations/transmitter/shared/logic/LogicTransmitterMerkleAdmin.sol";
import {RendererPressData} from "../src/implementations/transmitter/shared/renderer/RendererPressData.sol";

contract RouterTest is Test {
 
    // PUBLIC TEST VARIABLES
    Router router;
    FactoryTransmitterListings factory;
    PressTransmitterListings press;
    address feeRecipient = address(0x999);
    uint256 fee = 0.0005 ether;    
    LogicTransmitterMerkleAdmin logic;
    RendererPressData renderer;
    address admin = address(0x123);
    // NOTE: following merkle gymnastics conducted via lanyard.org
    // Merkle root generated from address(0x123) and address(0x321)
    bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
    // Proof value (convert to array) for address(0x123) on the merkleRoot provided above
    bytes32 merkleProofForAdminAndRoot = 0x71ef4e3ac02bbfe589f919cd478796b80265f2fa8354195b4d85495ddb4fbc5f;

    // Set up called before each test
    function setUp() public {

        router = new Router();
        press = new PressTransmitterListings(feeRecipient, fee);
        factory = new FactoryTransmitterListings(address(router), address(press));
        logic = new LogicTransmitterMerkleAdmin();
        renderer = new RendererPressData();
        
        address[] memory factoryToRegister = new address[](1);
        factoryToRegister[0] = address(factory);
        bool[] memory statusToRegister = new bool[](1);
        statusToRegister[0] = true;        
        router.registerFactories(factoryToRegister, statusToRegister);
    }  

    function test_sendData() public {
        // setup tokenless press
        PressTransmitterListings activePress = PressTransmitterListings(payable(createGenericPress()));
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
        // setup encoded inputs for sendData function
        bytes memory encodedData = abi.encode(proof, listings);

        uint256 fees = activePress.getFees(listings.length);
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        router.sendData{value: fees}(address(activePress), encodedData);        

        require(admin.balance == 1 ether - fees, "fees not correct");
        require(feeRecipient.balance == fees, "fees not correcthg");        
    }

    function createGenericPress() public returns (address) { 
        // setup initialAdmins array for logic init
        address[] memory initialAdmins = new address[](1);
        initialAdmins[0] = admin;
        // setup inputs for router setupPress call
        FactoryTransmitterListings.Inputs memory inputs = FactoryTransmitterListings.Inputs({
            pressName: "River",
            pressData: abi.encode("Press ContractURI"),
            initialOwner: admin,
            logic: address(logic),
            logicInit: abi.encode(initialAdmins, merkleRoot),
            renderer: address(renderer),
            rendererInit: new bytes(0)
        });
        (address newPress, address newPressDataPointer) = router.setupPress(address(factory), abi.encode(inputs));
        return newPress;
    }    
}