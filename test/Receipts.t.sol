// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";

import {Receipts} from "../src/tokens/Receipts.sol";

contract ReceiptsTest is Test {       

    //////////////////////////////////////////////////
    // PARAMETERS
    //////////////////////////////////////////////////  

    /* Actors */
    Account public eoa_operator;
    Account public eoa_recipient;
    Account public eoa_malicious;

    /* River infra */
    Receipts public receipts;

    //////////////////////////////////////////////////
    // SETUP
    //////////////////////////////////////////////////   

    // Set-up called before each test
    function setUp() public {
        eoa_operator = makeAccount("operator");
        eoa_recipient = makeAccount("recipient");
        eoa_malicious = makeAccount("malicious");
        receipts = new Receipts(eoa_operator.addr);
    }    

    //////////////////////////////////////////////////
    // MINT TESTS
    //////////////////////////////////////////////////   

    function test_mint() public {
        // prank into eoa that was set as owner for Receipts.sol
        vm.startPrank(eoa_operator.addr); 
        // mint receipt token to receipient
        receipts.mint(eoa_recipient.addr, 1);
        // Test that balance was updated
        require(receipts.ownerOf(1) == eoa_recipient.addr, "token balance not updated correctly -- owner of");
        require(receipts.balanceOf(eoa_recipient.addr) == 1, "token balance not updated correctly -- balance of");
    }           

    function test_Revert_OnlyOwner_mint() public {
        // prank into eoa that was set as operator for validator
        vm.startPrank(eoa_malicious.addr); 
        // Expect revert because validate being called by non owner
        vm.expectRevert("Ownable: caller is not the owner");
        // mint receipt token to receipient
        receipts.mint(eoa_malicious.addr, 1);
    }          

    //////////////////////////////////////////////////
    // UPDATE OPERATOR TESTS
    //////////////////////////////////////////////////       
}