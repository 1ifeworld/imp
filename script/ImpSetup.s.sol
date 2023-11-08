// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IdRegistry} from "../src/core/IdRegistry.sol";
import {NodeRegistry} from "../src/core/NodeRegistry.sol";
import {DelegateRegistry} from "../src/core/DelegateRegistry.sol";

contract ImpSetupScript is Script {

    IdRegistry idRegistry;
    NodeRegistry nodeRegistry;
    DelegateRegistry delegateRegistry;    
    
    function setUp() public {}

    function run() public {
        // NEW (?)
        // bytes32 privateKeyBytes = vm.envBytes32("PRIVATE_KEY");
        // uint256 deployerPrivateKey = uint256(privateKeyBytes);
        // Current        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        nodeRegistry = new NodeRegistry();
        idRegistry = new IdRegistry();
        delegateRegistry = new DelegateRegistry(address(idRegistry));

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ImpSetup.s.sol:ImpSetupScript -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/api
// forge script script/ImpSetup.s.sol:ImpSetupScript -vvvv --broadcast --fork-url http://localhost:8545