// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./TestHelper.sol";
import {EntryPoint} from "../../src/core/router/aa/EntryPoint.sol";
import {IEntryPoint} from "../../src/core/router/aa/interfaces/IEntryPoint.sol";
import {RiverWallet} from "../../src/core/router/RiverWallet.sol";
// Utils
import {Utilities} from "./Utilities.sol";
// More
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

contract RiverWalletTest is TestHelper {
    using ECDSA for bytes32;
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

    // Should return NO_SIG_VALIDATION on wrong signature due to mismatched signer
    function test_MismatchedSignerWrongSignature() public {
        (UserOperation memory op, RiverWallet accountImpl, uint256 preBalance, uint256 expectedPay,) = _validateUserOpSetup(address(0x1));                
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);
        vm.prank(entryPointAddress);
        uint256 validateDataResponse = accountImpl.validateUserOp(op, userOpHash, expectedPay);
        assertEq(validateDataResponse, 1);
    }

    // Should return NO_SIG_VALIDATION on wrong signature due to invalid nonce
    function test_NonceBasedWrongSignature() public {
        (UserOperation memory op,,,,) = _validateUserOpSetup(address(0));
        bytes32 zeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        UserOperation memory op2 = op;
        op2.nonce = 1;
        vm.prank(entryPointAddress);
        uint256 validateDataReponse = accountImpl.validateUserOp(op2, zeroHash, 0);
        assertEq(validateDataReponse, 1);
    }

    // #validateUserOp
    // Should pay
    // NOTE: test passes even if you pass an invalid signature
    function test_Payment() public {
        (, RiverWallet accountImpl, uint256 preBalance, uint256 expectedPay,) = _validateUserOpSetup(address(0));
        uint256 postBalance = utils.getBalance(address(accountImpl));
        assertEq(preBalance - postBalance, expectedPay);
    }

    //////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////

    function _validateUserOpSetup(address senderPassThrough)
        internal
        returns (UserOperation memory op, RiverWallet account1, uint256 preBalance, uint256 expectedPay, uint256 validateDataReponse)
    {
        Account memory newOwner = utils.createAddress("signer");        

        account1 = new RiverWallet(newOwner.addr, IEntryPoint(entryPoint));

        vm.deal(address(account1), 0.2 ether);

        op = defaultOp;
        op.sender = address(account1);
        // ovewrite calldata to our desired value
        /* creates valid signature */
        if (senderPassThrough == address(0)) {
            op.callData = abi.encode(newOwner.addr);
        } else {
            op.callData = abi.encode(senderPassThrough);
        }
        /* creates invalid signature */
        // op.callData = abi.encode(0x1);
        op = utils.signUserOp(op, newOwner.key, entryPointAddress, chainId);

        expectedPay = gasPrice * (op.callGasLimit + op.verificationGasLimit);    
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);     
        preBalance = utils.getBalance(address(account1));
        
        vm.prank(entryPointAddress);        
        account1.validateUserOp{gas: gasPrice}(op, userOpHash, expectedPay);
    }
}