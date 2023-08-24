// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {Router} from "../src/core/router/Router.sol";
import {Factory} from "../src/core/factory/Factory.sol";
import {IFactory} from "../src/core/factory/interfaces/IFactory.sol";
import {PressTokenless} from "../src/core/press/implementations/tokenless/PressTokenless.sol";
import {PressProxy} from "../src/core/press/proxy/PressProxy.sol";
import {IPress} from "../src/core/press/interfaces/IPress.sol";
import {IPressTypesV1} from "../src/core/press/types/IPressTypesV1.sol";
import {IPressTokenlessTypesV1} from "../src/core/press/implementations/tokenless/types/IPressTokenlessTypesV1.sol";
import {LogicRouterV1} from "../src/core/press/logic/LogicRouterV1.sol";
import {MockRenderer} from "./mocks/renderer/MockRenderer.sol";

contract RouterTest is Test {
 
    // PUBLIC TEST VARIABLES
    Router router;
    Factory factory;
    PressTokenless press;
    address feeRecipient = address(0x999);
    uint256 fee = 0.0005 ether;    
    LogicRouterV1 logic;
    MockRenderer renderer;
    address admin = address(0x123);
    // NOTE: following merkle gymnastics conducted via lanyard.org
    // Merkle root generated from address(0x123) and address(0x321)
    bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
    // Proof value (convert to array) for address(0x123) on the merkleRoot provided above
    bytes32 merkleProofForAdminAndRoot = 0x71ef4e3ac02bbfe589f919cd478796b80265f2fa8354195b4d85495ddb4fbc5f;

    // Set up called before each test
    function setUp() public {

        router = new Router();
        press = new PressTokenless(feeRecipient, fee);
        factory = new Factory(address(router), address(press));
        logic = new LogicRouterV1();
        renderer = new MockRenderer();
        
        address[] memory factoryToRegister = new address[](1);
        factoryToRegister[0] = address(factory);
        bool[] memory statusToRegister = new bool[](1);
        statusToRegister[0] = true;        
        router.registerFactories(factoryToRegister, statusToRegister);
    }  

    function test_sendData() public {
        // setup tokenless press
        PressTokenless activePress = PressTokenless(payable(createGenericPress()));
        // setup merkle proof for included address
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = merkleProofForAdminAndRoot;
        // setup listings array
        IPressTokenlessTypesV1.Listing[] memory listings = new IPressTokenlessTypesV1.Listing[](1);
        listings[0] = IPressTokenlessTypesV1.Listing({
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
        IFactory.Inputs memory inputs = IFactory.Inputs({
            pressName: "River",
            initialOwner: admin,
            logic: address(logic),
            logicInit: abi.encode(initialAdmins, merkleRoot),
            renderer: address(renderer),
            rendererInit: new bytes(0)
        });
        return router.setupPress(address(factory), abi.encode(inputs));   
    }    
}