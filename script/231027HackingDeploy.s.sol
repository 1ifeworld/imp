// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IdRegistry} from "../src/core/IdRegistry.sol";
import {NodeRegistry} from "../src/core/NodeRegistry.sol";
import {DelegateRegistry} from "../src/core/DelegateRegistry.sol";
import {Receipts} from "../src/tokens/Receipts.sol";


contract DeployCore is Script {

    IdRegistry idRegistry;
    NodeRegistry nodeRegistry;
    DelegateRegistry delegateRegistry;
    Receipts receipts;
    address operator = 0x004991c3bbcF3dd0596292C80351798965070D75;
    
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // nodeRegistry = new NodeRegistry();
        idRegistry = new IdRegistry("IdRegistry", "IDR");
        delegateRegistry = new DelegateRegistry(address(idRegistry));
        receipts = new Receipts(operator);

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/231027HackingDeploy.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/api