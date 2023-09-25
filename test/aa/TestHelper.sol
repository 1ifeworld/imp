// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {EntryPoint} from "../../src/core/router/aa/EntryPoint.sol";
import {IEntryPoint} from "../../src/core/router/aa/interfaces/IEntryPoint.sol";
import {UserOperation} from "../../src/core/router/aa/interfaces/UserOperation.sol";
import {RiverWallet} from "../../src/core/router/RiverWallet.sol";

contract TestHelper is Test {
    Account internal accountOwner;
    EntryPoint internal entryPoint;
    // RiverWallet internal accountProxy; // this should become account proxy
    RiverWallet internal accountImpl;
    // SimpleAccountFactory internal simpleAccountFactory;

    address internal accountAddress;
    address internal entryPointAddress;

    uint256 internal chainId = vm.envOr("CHAIN_ID", uint256(31337));
    uint256 internal constant globalUnstakeDelaySec = 2;
    uint256 internal constant paymasterStake = 2 ether;
    bytes internal constant defaultBytes = bytes("");

    UserOperation internal defaultOp = UserOperation({
        sender: 0x0000000000000000000000000000000000000000,
        nonce: 0,
        initCode: defaultBytes,
        callData: defaultBytes,
        callGasLimit: 200000,
        verificationGasLimit: 100000,
        preVerificationGas: 21000,
        maxFeePerGas: 3000000000,
        maxPriorityFeePerGas: 1,
        paymasterAndData: defaultBytes,
        signature: defaultBytes
    });

    function deployEntryPoint(uint256 _salt) internal {
        entryPoint = new EntryPoint{salt: bytes32(_salt)}();
        entryPointAddress = address(entryPoint);
    }

    function createAccount(IEntryPoint entrypoint) internal {
        accountImpl = new RiverWallet(accountOwner.addr, entrypoint);
        accountAddress = address(accountImpl);
    }

    // function createFactory(uint256 _factorySalt) internal returns (SimpleAccountFactory _factory) {
    //     _factory = new SimpleAccountFactory{salt: bytes32(_factorySalt)}(entryPoint);
    // }

    // function createAccountWithFactory(uint256 _accountSalt) internal returns (SimpleAccount, address) {
    //     simpleAccountFactory.createAccount(accountOwner.addr, _accountSalt);
    //     address _accountAddress = simpleAccountFactory.getAddress(accountOwner.addr, _accountSalt);
    //     return (SimpleAccount(payable(_accountAddress)), _accountAddress);
    // }

    // function createAccountWithFactory(uint256 _accountSalt, address _ownerAddress)
    //     internal
    //     returns (SimpleAccount, address)
    // {
    //     simpleAccountFactory.createAccount(_ownerAddress, _accountSalt);
    //     address _accountAddress = simpleAccountFactory.getAddress(_ownerAddress, _accountSalt);
    //     return (SimpleAccount(payable(_accountAddress)), _accountAddress);
    // }
}