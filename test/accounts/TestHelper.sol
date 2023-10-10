// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "account-abstraction/core/EntryPoint.sol";

import {RiverAccount} from "../../src/accounts/RiverAccount.sol";
import "../../src/accounts/AccountFactory.sol";

contract TestHelper is Test {
    Account internal riverNetSigner;
    Account internal accountAdmin;
    EntryPoint internal entryPoint;
    RiverAccount internal account;
    RiverAccount internal implementation;
    AccountFactory internal accountFactory;

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

    function createAccount(uint256 _factorySalt, uint256 _accountSalt) internal {
        accountFactory = new AccountFactory{salt: bytes32(_factorySalt)}(entryPoint);
        implementation = accountFactory.accountImplementation();
        accountFactory.createAccount(accountAdmin.addr, _accountSalt);
        accountAddress = payable(accountFactory.getAddress(accountAdmin.addr, _accountSalt));
        account = RiverAccount(payable(accountAddress));
    }

    function createFactory(uint256 _factorySalt) internal returns (AccountFactory _factory) {
        _factory = new AccountFactory{salt: bytes32(_factorySalt)}(entryPoint);
    }

    function createAccountWithFactory(uint256 _factorySalt, uint256 _accountSalt) internal returns (RiverAccount, address) {
        accountFactory = new AccountFactory{salt: bytes32(_factorySalt)}(entryPoint);        
        accountFactory.createAccount(accountAdmin.addr, _accountSalt);
        address _accountAddress = accountFactory.getAddress(accountAdmin.addr, _accountSalt);
        return (RiverAccount(payable(_accountAddress)), _accountAddress);
        
    }

    function createAccountWithFactory(uint256 _accountSalt, address _adminAddress)
        internal
        returns (RiverAccount, address)
    {
        accountFactory.createAccount(_adminAddress, _accountSalt);
        address _accountAddress = accountFactory.getAddress(_adminAddress, _accountSalt);
        return (RiverAccount(payable(_accountAddress)), _accountAddress);
    }
}