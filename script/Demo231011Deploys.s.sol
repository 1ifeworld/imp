// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ChannelRegistry} from "../src/core/ChannelRegistry.sol";
import {IdRegistry} from "../src/core/IdRegistry.sol";
import {RiverAccount} from "../src/accounts/RiverAccount.sol";
import {RiverAccountFactory} from "../src/accounts/RiverAccountFactory.sol";
import {IEntryPoint} from "account-abstraction/core/EntryPoint.sol";


contract DeployCore is Script {

    ChannelRegistry channelRegistry;
    IdRegistry idRegistry;
    RiverAccountFactory riverAccountFactory;
    address riverNetSigner = 0x004991c3bbcF3dd0596292C80351798965070D75;
    IEntryPoint entryPoint = IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);
    address initialAdminOnAccount = 0x806164c929Ad3A6f4bd70c2370b3Ef36c64dEaa8;
    uint256 salt = 1234;
    
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        channelRegistry = new ChannelRegistry();
        idRegistry = new IdRegistry();
        riverAccountFactory = new RiverAccountFactory(entryPoint, riverNetSigner);

        // test deploy account
        riverAccountFactory.createAccount(initialAdminOnAccount, 1234);

        // teset create channel
        // setup new channel inputs
        uint256 mockRid = 1920;
        uint256 mockAccessScehma = 110;
        string memory mockChannelUri = "ipfs://bafybeidw4rmzno2ovlppggmhoal3tvuzi2ufbtaudyc37jqnj5pm5fyble/1"; 
        address[] memory admins = new address[](1);
        admins[0] = initialAdminOnAccount;     
        bytes32 merkleRoot = 0xb494f4f51d001f39414763c301687a74a238d923b8c2f89162dd568edabce400;
        bytes memory mockAccessSchemaData = abi.encode(admins, merkleRoot);
        // encode channel inputs
        bytes memory encodedNewChannelData = abi.encode(mockRid, mockAccessScehma, mockAccessSchemaData, mockChannelUri);            
        // create channel
        channelRegistry.newChannel(encodedNewChannelData);

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/Demo231011Deploys.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/api
