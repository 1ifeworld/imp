// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TestHelper.sol";
import {EntryPoint} from "../../src/core/router/aa/EntryPoint.sol";
import {IEntryPoint} from "../../src/core/router/aa/interfaces/IEntryPoint.sol";
import {RiverWallet} from "../../src/core/router/RiverWallet.sol";
//Utils
import {Utilities} from "./Utilities.sol";

contract RiverWalletTest is TestHelper {
    uint256 internal constant gasPrice = 1000000000;
    Utilities internal utils;

    function setUp() public {
        utils = new Utilities();
        accountOwner = utils.createAddress("simple_account_owner");
        deployEntryPoint(1201);
        createAccount(IEntryPoint(entryPoint));
    }

    // Owner should be able to call transfer
    function test_TransferByOwner() public {
        vm.deal(accountAddress, 2 ether);
        Account memory receiver = utils.createAddress("receiver");

        vm.prank(accountOwner.addr);
        accountImpl.transferToTarget(receiver.addr, 1 ether);
        assertEq(utils.getBalance(accountAddress), 1 ether);
    }

    // Other account should not be able to call transfer
    function test_TransferByNonOwner(address receiver) public {
        vm.deal(accountAddress, 3 ether);
        vm.expectRevert(abi.encodeWithSignature("Only_Owner()"));
        accountImpl.transferToTarget(receiver, 1 ether);
    }

    /* NOTE: START HERE. THIS IS WHERE I LEFT OFF */
    // #validateUserOp
    // Should pay
    // function test_Payment() public {
    //     (, RiverWallet account1, uint256 preBalance, uint256 expectedPay) = _validateUserOpSetup();
    //     uint256 postBalance = utils.getBalance(address(account1));
    //     assertEq(preBalance - postBalance, expectedPay);
    // }

    // // Should return NO_SIG_VALIDATION on wrong signature
    // function test_WrongSignature() public {
    //     (UserOperation memory op,,,) = _validateUserOpSetup();
    //     bytes32 zeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
    //     UserOperation memory op2 = op;
    //     op2.nonce = 1;

    //     vm.prank(entryPointAddress);
    //     uint256 deadline = account.validateUserOp(op2, zeroHash, 0);

    //     assertEq(deadline, 1);
    // }

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////

    function _validateUserOpSetup()
        internal
        returns (UserOperation memory op, RiverWallet account1, uint256 preBalance, uint256 expectedPay)
    {
        Account memory newOwner = utils.createAddress("signer");

        account1 = new RiverWallet(newOwner.addr, IEntryPoint(entryPoint));
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