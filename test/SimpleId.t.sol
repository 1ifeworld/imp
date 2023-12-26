// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console2} from "forge-std/Test.sol";

import {SimpleId} from "../src/SimpleId.sol";
import {SimpleId} from "../src/SimpleId.sol";
import {EIP712} from "../src/abstract/EIP712.sol";

contract SimpleIdTest is Test {       


    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////  

    /* Actors */
    Account public eoaRegistrar;
    Account public eoaRecipient;
    Account public eoaMalicious;

    /* IMP infra */
    SimpleId public simpleId;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test
    function setUp() public {
        eoaRegistrar = makeAccount("registrar");
        eoaRecipient = makeAccount("recipient");        
        eoaMalicious = makeAccount("malicious");
        simpleId = new SimpleId();
    }    

    //////////////////////////////////////////////////
    // REGISTER TESTS
    //////////////////////////////////////////////////   

    function test_registerFor() public {
        bytes memory sig = _signRegister(
            eoaRecipient.key,
            eoaRecipient.addr,
            eoaRegistrar.addr,
            block.timestamp + 1
        );
        vm.prank(eoaRegistrar.addr);
        simpleId.registerFor(
            eoaRecipient.addr,
            eoaRegistrar.addr,
            block.timestamp + 1,
            sig
        );
        assertEq(simpleId.idCounter(), 1);
        assertEq(simpleId.idOf(eoaRecipient.addr), 1);
        assertEq(simpleId.custodyOf(1), eoaRecipient.addr);
        assertEq(simpleId.recoveryOf(1), eoaRegistrar.addr);
    }

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////  

    function _sign(uint256 privateKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }        

    function _signRegister(
        uint256 pk,
        address to,
        address recovery,
        uint256 deadline
    ) internal returns (bytes memory signature) {
        address signer = vm.addr(pk);
        bytes32 digest = simpleId.hashTypedDataV4(
            keccak256(abi.encode(simpleId.REGISTER_TYPEHASH(), to, recovery, simpleId.nonces(signer), deadline))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertEq(signature.length, 65);
    }      
}