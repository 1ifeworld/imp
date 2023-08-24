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

    // MERKLE ROOT HARDCODE
    bytes32 merkleRoot = 0x640c46ede06e553b55939cfbfe691196cd77036569f3459a72a23a803c2d0dd3;
    address includedAddress_1 = 0xE7746f79bF98e685e6a1ac80D74d2935431041d5;
    bytes32 includedAddress_1_Proof = 0xb3a751cbc121f97d50361c8c86ffc8b67e895e51f3df3d6f8bb965aac8a9b726;    

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


    
    // address constant head = address(0x1);

    function test_send() public {
        // setup tokenless press
        PressTokenless activePress = PressTokenless(payable(createGenericPress()));
        // setup merkle proof for included address
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = includedAddress_1_Proof;
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

    // function test_transmit() public {
    //     Counter.Listing[] memory listings = new Counter.Listing[](1);
    //     listings[0] = Counter.Listing({
    //         chainId: 1,
    //         tokenId: 1,
    //         listingAddress: address(0x123),
    //         hasTokenId: true
    //     });        
    //     bytes memory data = abi.encode(listings);

    //     vm.prank(head);
    //     counter.transmitData(head, data);
    // }

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
