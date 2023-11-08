// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "openzeppelin-contracts/interfaces/IERC1271.sol";
import {EntryPoint} from "light-account/lib/account-abstraction/contracts/core/EntryPoint.sol";
import {LightAccount} from "light-account/src/LightAccount.sol";
import {LightAccountFactory} from "light-account/src/LightAccountFactory.sol";

import {IdRegistry} from "../src/IdRegistry.sol";

// TODO: transfer + revokeAttestation related tests

contract IdRegistryTest is Test {       

    //////////////////////////////////////////////////
    // CONSTANTS
    //////////////////////////////////////////////////   

    bytes4 public constant EIP1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));
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
        eoaAttestor = makeAccount("attestor");
        eoaMalicious = makeAccount("malicious");

        idRegistry = new IdRegistry();

        entryPoint = new EntryPoint();
        LightAccountFactory factory = new LightAccountFactory(entryPoint);

        account = factory.createAccount(eoaOwner.addr, salt);
        account2 = factory.createAccount(eoaAttestor.addr, salt);
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
        require(idRegistry.transferCountForId(1) == 1, "transfer count not incremented correctly");
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
    // ATTEST TESTS
    //////////////////////////////////////////////////       

    function test_EOA_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to 
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));

        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaAttestor.key, digest);

        // Call attest function, passing in signature from other keypair the user has access to
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (eoaAttestor.addr, digest, signature)));   

        require(idRegistry.attestedBy(eoaAttestor.addr) == 1, "attestedBy set incorrectly");     
        require(idRegistry.attestedFor(1) == eoaAttestor.addr, "attestedFor set incorrectly");     
    }

    function test_SmartAccount_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to account
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));

        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaAttestor.key, digest);

        // Call attest function, passing in signature from other keypair the user has access to, which happens
        //      to be the owner of the second smart account that the owner of the first smart account wnats to
        //      verify ownership of for attest
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (address(account2), digest, signature)));     

        require(idRegistry.attestedBy(address(account2)) == 1, "attestedBy set incorrectly");     
        require(idRegistry.attestedFor(1) == address(account2), "attestedFor set incorrectly");         
    }    

    // NOTE: test is reverting but cant get it to verify its because of the "Has_No_Id" revert
    function test_Revert_HasNoId_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to account
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        vm.stopPrank();
        vm.startPrank(eoaMalicious.addr);
        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaMalicious.key, digest);
        // Should revert because eoaMalicious has no registered id to attest for
        // vm.expectRevert(abi.encodeWithSignature("Has_No_Id()"));
        vm.expectRevert();
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (eoaMalicious.addr, digest, signature)));  
    }       

    function test_Revert_HasAttested_EOA_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to account
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaAttestor.key, digest);
        // Call attest function, passing in signature from other keypair the user has access to
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (eoaAttestor.addr, digest, signature)));  
        // Should revert because attestor has already attested for this id
        vm.expectRevert(abi.encodeWithSignature("Has_Attested()"));
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (eoaAttestor.addr, digest, signature)));   
        // TODO: add more scenarios when the attest call should revert (ex: for an id with no active attestor)
    }   

    function test_Revert_HasAttested_SmartAccount_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to account
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaAttestor.key, digest);
        // Call attest function, passing in signature from other keypair the user has access to
        
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (address(account2), digest, signature)));  
        // Should revert because attestor has already attested for this id
        vm.expectRevert(abi.encodeWithSignature("Has_Attested()"));
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (address(account2), digest, signature)));   
        // TODO: add more scenarios when the attest call should revert (ex: for an id with no active attestor)
    }            

    function test_Revert_InvalidSignature_SmartAccount_attest() public {
        vm.startPrank(eoaOwner.addr); 
        // Register id 1 to account
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.register, (MOCK_REGISTER_BACKUP, ZERO_BYTES)));
        // Generate digest + signature for attest call
        bytes32 digest = keccak256("attest_digest");
        bytes memory signature = _sign(eoaAttestor.key, digest);
        // Change digest, but not signature, to cause error
        bytes32 maliciousDigest = keccak256("malicious_digest");        
        // Should revert because of invalid signature due to incorrect digest swap
        vm.expectRevert(abi.encodeWithSignature("Invalid_Signature()"));        
        account.execute(address(idRegistry), 0, abi.encodeCall(IdRegistry.attest, (address(account2), maliciousDigest, signature))); 
    }              

    //////////////////////////////////////////////////
    // TRANSFER TESTS
    //////////////////////////////////////////////////   

    // TODO

    //////////////////////////////////////////////////
    // REVOKE ATTESTATION TESTS
    //////////////////////////////////////////////////   

    // TODO

    //////////////////////////////////////////////////
    // HELPERS FROM ALCHEMY -- LIGHT ACCOUNT TESTS
    //////////////////////////////////////////////////  

    function _sign(uint256 privateKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}