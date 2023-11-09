// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {EntryPoint} from "light-account/lib/account-abstraction/contracts/core/EntryPoint.sol";
import {LightAccount} from "light-account/src/LightAccount.sol";
import {LightAccountFactory} from "light-account/src/LightAccountFactory.sol";

import {IdRegistry} from "../src/IdRegistry.sol";

// TODO: transfer + recovery related tests

contract IdRegistryTest is Test {       

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////   

    address public constant MOCK_REGISTER_BACKUP = address(0x123);
    bytes public constant ZERO_BYTES = new bytes(0);

    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////  

    /* Actors */
    Account public eoaOwner;
    Account public eoaAttestor;
    Account public eoaMalicious;     

    /* IMP infra */
    IdRegistry public idRegistry;

    /* Smart account infra */
    EntryPoint public entryPoint;
    LightAccount public account;
    LightAccount public account2;
    LightAccount public contractOwnedAccount;
    uint256 public salt = 1;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test
    function setUp() public {
        eoaOwner = makeAccount("owner");
        eoaMalicious = makeAccount("malicious");

        idRegistry = new IdRegistry();

        entryPoint = new EntryPoint();
        LightAccountFactory factory = new LightAccountFactory(entryPoint);

        account = factory.createAccount(eoaOwner.addr, salt);
    }    

    //////////////////////////////////////////////////
    // REGISTER TESTS
    //////////////////////////////////////////////////   

    function test_register() public {
        // prank into eoa that is the owner of light account
        vm.startPrank(eoaOwner.addr); 
        // call `execute` on light account, passing in instructions to call `register` on idRegistry from light account 
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        require(idRegistry.idCount() == 1, "id count not incremented correctly");
        require(idRegistry.idOwnedBy(address(account)) == 1, "id 1 not registered correctly");
        require(idRegistry.backupForId(1) == MOCK_REGISTER_BACKUP, "id backup not set correctly");
    }

    function test_Revert_OneIdPerAddress_register() public {
        // prank into eoa that is the owner of light account
        vm.startPrank(eoaOwner.addr); 
        // call `execute` on light account, passing in instructions to call `register` on idRegistry from light account 
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        // expect revert because account can only have one id registered at a time
        vm.expectRevert(abi.encodeWithSignature("Has_Id()"));
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
    }      

    //////////////////////////////////////////////////
    // TRANSFER TESTS
    //////////////////////////////////////////////////   

    // TODO

    //////////////////////////////////////////////////
    // RECOVERY TESTS
    //////////////////////////////////////////////////   

    // TODO
}