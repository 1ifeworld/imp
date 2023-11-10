// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IdRegistry} from "../src/IdRegistry.sol";
import {NodeRegistry} from "../src/NodeRegistry.sol";
import {DelegateRegistry} from "../src/DelegateRegistry.sol";
import {AttestationRegistry} from "../src/AttestationRegistry.sol";

contract ImpSetupScript is Script {

    IdRegistry idRegistry;
    NodeRegistry nodeRegistry;
    DelegateRegistry delegateRegistry;    
    AttestationRegistry attestationRegistry;    
    
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
        attestationRegistry = new AttestationRegistry();

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ImpSetup.s.sol:ImpSetupScript -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/api
// forge script script/ImpSetup.s.sol:ImpSetupScript -vvvv --broadcast --fork-url http://localhost:8545