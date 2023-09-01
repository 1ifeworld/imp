// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


import {Router} from "../src/core/router/Router.sol";
import {FactoryTransmitterListings} from "../src/implementations/transmitter/listings/factory/FactoryTransmitterListings.sol";
import {PressTransmitterListings} from "../src/implementations/transmitter/listings/press/PressTransmitterListings.sol";
import {IListing} from "../src/implementations/transmitter/listings/types/IListing.sol";
import {LogicTransmitterMerkleAdmin} from "../src/implementations/transmitter/shared/logic/LogicTransmitterMerkleAdmin.sol";
import {RendererPressData} from "../src/implementations/transmitter/shared/renderer/RendererPressData.sol";

contract SetupPressCore is Script {

    Router router;
    FactoryTransmitterListings factory;
    LogicTransmitterMerkleAdmin logic;
    RendererPressData renderer;
    address feeRecipient;
    uint256 fee;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        feeRecipient = address(0x999);
        fee = 0.0005 ether;    

        router = Router(0x880253BF121374121fE21948DE3A426a695924ee);
        factory = FactoryTransmitterListings(0x785e41cEa803637A34E6a3EA15dD533526B33740);
        logic = LogicTransmitterMerkleAdmin(0x4a38667ADcD14d47aB927140E83aAfA64B281E4c);
        renderer = RendererPressData(0x85044D4bb1cf8Fc9DadA5b4F0A20b0Fda1076924);

        // create new press with above settings
        createListingsTransmitterPress();

        vm.stopBroadcast();
    }

    function createListingsTransmitterPress() public returns (address) { 
        // setup initialAdmins array for logic init
        address[] memory initialAdmins = new address[](5);
        initialAdmins[0] = 0xF2365A26f766109b5322B0f90d71c21bF32bda04;
        initialAdmins[1] = 0x6fF78174FD667fD21d82eE047d38dc15b5440d71;
        initialAdmins[2] = 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170;
        initialAdmins[3] = 0xbC68dee71fd19C6eb4028F98F3C3aB62aAD6FeF3;
        initialAdmins[4] = 0x4C53C6D546C9E38db56040Ab505460A9187A5281;
        bytes32 merkleRoot = 0x4759da724e26242f293bcda53b26221a2e16ebd5f00c3260ffab1281b4ac6c22;
        // setup inputs for router setupPress call
        FactoryTransmitterListings.Inputs memory inputs = FactoryTransmitterListings.Inputs({
            pressName: "Lifeworld",
            pressData: abi.encode("ipfs://bafkreiahcazxyfukq2o6fyyhqacsepcmx5f5p5pd35tkdsh7sxgida42om"),
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

// ======= RUN SCRIPTS =====

// source .env
// forge script script/NewTransmitter.s.sol:SetupPressCore -vvvv --rpc-url $RPC_URL --broadcast