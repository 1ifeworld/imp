// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./TestHelper.sol";
import "../../src/accounts/RiverAccount.sol";
import "../../src/accounts/AccountFactory.sol";

import "account-abstraction/core/EntryPoint.sol";
//Utils
import {Utilities} from "./Utilities.sol";

contract RiverAccountTest is TestHelper {
    uint256 internal constant gasPrice = 1000000000;
    Utilities internal utils;

    function setUp() public {
        utils = new Utilities();
        riverNetSigner = utils.createAddress("river_net_signer");
        accountAdmin = utils.createAddress("account_admin");
        deployEntryPoint(1201);
        createAccount(1202, 1203);
    }

    // Owner should be able to call transfer
    function test_TransferEth() public {
        (RiverAccount account1, address accountAddress1) = createAccountWithFactory(1204, accountAdmin.addr);
        vm.deal(accountAddress1, 2 ether);
        Account memory receiver = utils.createAddress("receiver");
        vm.prank(accountAdmin.addr);
        account1.execute(receiver.addr, 1 ether, defaultBytes);
        assertEq(utils.getBalance(accountAddress1), 1 ether);
    }

    // Other account should not be able to call transfer
    function test_Revert_NonAdmin_TransferEth(address receiver) public {
        (RiverAccount account1,) = createAccountWithFactory(1205, accountAdmin.addr);
        vm.deal(accountAddress, 3 ether);
        vm.expectRevert("account: not Admin or EntryPoint");
        account.execute(receiver, 1 ether, defaultBytes);
    }

    // #validateUserOp
    // Should pay
    function test_Payment() public {
        (, RiverAccount account1, uint256 preBalance, uint256 expectedPay,) = _validateUserOpSetup();
        uint256 postBalance = utils.getBalance(address(account1));
        assertEq(preBalance - postBalance, expectedPay);
    }

    // Should return NO_SIG_VALIDATION on invalid signature
    function test_Revert_InvalidSignature() public {
        (UserOperation memory op,,,,) = _validateUserOpSetup();
        bytes32 zeroHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        UserOperation memory op2 = op;
        op2.nonce = 1;

        vm.prank(entryPointAddress);
        uint256 deadline = account.validateUserOp(op2, zeroHash, 0);

        assertEq(deadline, 1);
    }

    // Testing giveApproval functionality on RiverAccount impls
    function test_giveApproval() public {
        (RiverAccount account1,) = createAccountWithFactory(1205, accountAdmin.addr);
        vm.prank(accountAdmin.addr);
        account1.giveApproval(riverNetSigner.addr);
        assertEq(account1.accessLevel(riverNetSigner.addr), 1);
    }    

    // Testing giveApproval functionality on RiverAccount impls
    function test_Revert_NotAdmin_giveApproval() public {
        (RiverAccount account1,) = createAccountWithFactory(1205, accountAdmin.addr);
        vm.prank(address(0x123));
        vm.expectRevert();
        account1.giveApproval(riverNetSigner.addr);
    }

    function test_ValidUserOp_FromAdmin() public {
        (,,,, uint256 validateOpResponse) = _validateUserOpSetup();   
        require(validateOpResponse == 0, "invalid op");
    }           

    function test_ValidUserOp_FromApproval() public {
        (RiverAccount account1,) = createAccountWithFactory(1205, accountAdmin.addr);
        vm.deal(address(account1), 0.2 ether);
        vm.prank(accountAdmin.addr);
        account1.giveApproval(riverNetSigner.addr);

        UserOperation memory op = defaultOp;
        op.sender = address(account1);
        op = utils.signUserOp(op, riverNetSigner.key, entryPointAddress, chainId);

        uint256 expectedPay = gasPrice * (op.callGasLimit + op.verificationGasLimit);
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);
        uint256 preBalance = utils.getBalance(address(account1));        

        vm.prank(entryPointAddress);
        uint256 validOp = account1.validateUserOp{gas: gasPrice}(op, userOpHash, expectedPay);    
        require(validOp == 0, "invalid op");
    }       

    function test_Revert_NotAdminOrApproved_ValidUserOp() public {
                (RiverAccount account1,) = createAccountWithFactory(1205, accountAdmin.addr);
        vm.deal(address(account1), 0.2 ether);
        vm.prank(accountAdmin.addr);
        account1.giveApproval(riverNetSigner.addr);

        UserOperation memory op = defaultOp;
        op.sender = address(account1);
        Account memory maliciousSigner = utils.createAddress("malicious_signer");
        op = utils.signUserOp(op, maliciousSigner.key, entryPointAddress, chainId);

        uint256 expectedPay = gasPrice * (op.callGasLimit + op.verificationGasLimit);
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);
        uint256 preBalance = utils.getBalance(address(account1));        

        vm.prank(entryPointAddress);
        uint256 invalidOp = account1.validateUserOp{gas: gasPrice}(op, userOpHash, expectedPay);    
        require(invalidOp == 1, "op was not invalid as expected");        
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

    // entry point
    // test that we can validate a userOp created by an approved signature

    function _validateUserOpSetup()
        internal
        returns (UserOperation memory op, RiverAccount account1, uint256 preBalance, uint256 expectedPay, uint256 validateOpResp)
    {
        Account memory newAdmin = utils.createAddress("signer");

        AccountFactory _factory = createFactory(1208);
        account1 = _factory.createAccount(newAdmin.addr, 1209);
        vm.deal(address(account1), 0.2 ether);

        op = defaultOp;
        op.sender = address(account1);
        op = utils.signUserOp(op, newAdmin.key, entryPointAddress, chainId);

        expectedPay = gasPrice * (op.callGasLimit + op.verificationGasLimit);
        bytes32 userOpHash = utils.getUserOpHash(op, entryPointAddress, chainId);
        preBalance = utils.getBalance(address(account1));

        vm.prank(entryPointAddress);
        validateOpResp = account1.validateUserOp{gas: gasPrice}(op, userOpHash, expectedPay);
    }
}