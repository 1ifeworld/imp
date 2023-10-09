// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestHelper.sol";
import {Account} from "../../src/accounts/Account.sol";
import {AccountFactory} from "../../src/accounts/AccountFactory.sol";

import "account-abstraction/core/EntryPoint.sol";
//Utils
import {Utilities} from "./Utilities.sol";

contract AccountTest is TestHelper {
    uint256 internal constant gasPrice = 1000000000;
    Utilities internal utils;

    function setUp() public {
        utils = new Utilities();
        accountOwner = utils.createAddress("account_owner");
        deployEntryPoint(1201);
        createAccount(1202, 1203);
    }

    // Owner should be able to call transfer
    function test_TransferByOwner() public {
        (Account account1, address accountAddress1) = createAccountWithFactory(1204, accountOwner.addr);
        vm.deal(accountAddress1, 2 ether);
        Account memory receiver = utils.createAddress("receiver");
        vm.prank(accountOwner.addr);
        account1.execute(receiver.addr, 1 ether, defaultBytes);
        assertEq(utils.getBalance(accountAddress1), 1 ether);
    }

    // Other account should not be able to call transfer
    function test_TransferByNonOwner(address receiver) public {
        (Account account1,) = createAccountWithFactory(1205, accountOwner.addr);
        vm.deal(accountAddress, 3 ether);
        vm.expectRevert("account: not Owner or EntryPoint");
        account1.execute(receiver, 1 ether, defaultBytes);
    }

    // #validateUserOp
    // Should pay
    function test_Payment() public {
        (, Account account1, uint256 preBalance, uint256 expectedPay) = _validateUserOpSetup();
        uint256 postBalance = utils.getBalance(address(account1));
        assertEq(preBalance - postBalance, expectedPay);
    }

    // Should return NO_SIG_VALIDATION on wrong signature
    function test_WrongSignature() public {
        (UserOperation memory op,,,) = _validateUserOpSetup();
        bytes32 zeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        UserOperation memory op2 = op;
        op2.nonce = 1;

        vm.prank(entryPointAddress);
        uint256 deadline = account.validateUserOp(op2, zeroHash, 0);

        assertEq(deadline, 1);
    }

    // AccountFactory
    // Sanity: check deployer
    function test_Deployer() public {
        Account memory newOwner = utils.createAddress("new_owner");
        AccountFactory _factory = createFactory(1206);
        address testAccount = _factory.getAddress(newOwner.addr, 1207);
        assertEq(utils.isContract(testAccount), false);
        _factory.createAccount(newOwner.addr, 1207);
        assertEq(utils.isContract(testAccount), true);
    }

    function _validateUserOpSetup()
        internal
        returns (UserOperation memory op, Account account1, uint256 preBalance, uint256 expectedPay)
    {
        Account memory newOwner = utils.createAddress("signer");

        AccountFactory _factory = createFactory(1208);
        account1 = _factory.createAccount(newOwner.addr, 1209);
        vm.deal(address(account1), 0.2 ether);

        op = defaultOp;
        op.sender = address(account1);
        op = utils.signUserOp(op, newOwner.key, entryPointAddress, chainId);

        expectedPay = gasPrice * (op.callGasLimit + op.verificationGasLimit);
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);
        preBalance = utils.getBalance(address(account1));

        vm.prank(entryPointAddress);
        account1.validateUserOp{gas: gasPrice}(op, userOpHash, expectedPay);
    }
}