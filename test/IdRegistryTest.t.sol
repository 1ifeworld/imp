// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {IdRegistry} from "../src/core/IdRegistry.sol";

contract IdRegistryTest is Test {
    /* IdRegistry architecture */
    IdRegistry idRegistry;
    /* CONSTANTS */
    address user = address(0x444);
    address backup = address(0x007);

    // Set up called before each test
    function setUp() public {
        idRegistry = new IdRegistry();  
    }    

    function test_register() public {
        vm.prank(user);
        uint256 rid = idRegistry.register(backup);
        require(rid == 1, "rid not incremented correctly");
    }

    // 68k gas for first registration since counter going from zero -> not zero
    // 46k gas for second registration (and beyond) since counter going from not zero -> not zero
    function test_secondRegister() public {
        vm.prank(user);
        uint256 firstRid = idRegistry.register(backup);
        vm.prank(address(0x1111));
        uint256 secondRid = idRegistry.register(backup);
        require(firstRid == 1, "first rid not incremented correctly");
        require(secondRid == 2, "second rid not incremented correctly");
    }    

    function test_Revert_OneIdPerAddress_register() public {
        vm.startPrank(user);
        idRegistry.register(backup);
        // should fail because once user has registered an id,
        // cant register another one unless they transfer the id first
        vm.expectRevert(abi.encodeWithSignature("HasId()"));
        idRegistry.register(backup);
    }    

    /* HELPERS */
}