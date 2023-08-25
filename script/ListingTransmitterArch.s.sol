// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


import {Router} from "../src/core/router/Router.sol";
import {FactoryTransmitterListings} from "../src/implementations/transmitter/listings/factory/FactoryTransmitterListings.sol";
import {PressTransmitterListings} from "../src/implementations/transmitter/listings/press/PressTransmitterListings.sol";
import {LogicTransmitterMerkleAdmin} from "../src/implementations/transmitter/shared/logic/LogicTransmitterMerkleAdmin.sol";
import {RendererPressData} from "../src/implementations/transmitter/shared/renderer/RendererPressData.sol";

contract DeployCore is Script {

    Router router;
    FactoryTransmitterListings factory;
    PressTransmitterListings press;
    address feeRecipient;
    uint256 fee;
    LogicTransmitterMerkleAdmin logic;
    RendererPressData renderer;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        feeRecipient = address(0x999);
        fee = 0.0005 ether;    

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

        address newListingsTransmitterPress = createListingsTransmitterPress();

        vm.stopBroadcast();
    }

    function createListingsTransmitterPress() public returns (address) { 
        // setup initialAdmins array for logic init
        address[] memory initialAdmins = new address[](4);
        initialAdmins[0] = 0xF2365A26f766109b5322B0f90d71c21bF32bda04;
        initialAdmins[1] = 0x6fF78174FD667fD21d82eE047d38dc15b5440d71;
        initialAdmins[2] = 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170;
        initialAdmins[3] = 0xbC68dee71fd19C6eb4028F98F3C3aB62aAD6FeF3;
        bytes32 merkleRoot = 0xc533eac80407cbebf71cb09a125bfa09eeedbec58f4926e620526eef5bfce8b9;
        // setup inputs for router setupPress call
        FactoryTransmitterListings.Inputs memory inputs = FactoryTransmitterListings.Inputs({
            pressName: "River",
            pressData: abi.encode("River contractURI"),
            initialOwner: 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170,
            logic: address(logic),
            logicInit: abi.encode(initialAdmins, merkleRoot),
            renderer: address(renderer),
            rendererInit: new bytes(0)
        });
        (address newPress, address newPressDataPointer) = router.setupPress(address(factory), abi.encode(inputs));
        return newPress;
    }        
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ListingTransmitterArch.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify
// forge script script/ListingTransmitterArch.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url {block exploerer verifier url}
// forge script script/ListingTransmitterArch.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/api

// optimism goerli verifier url https://api-goerli-optimistic.etherscan.io/api