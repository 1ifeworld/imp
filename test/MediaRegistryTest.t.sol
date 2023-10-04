// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";

import {MediaRegistry} from "../src/core/MediaRegistry.sol";

contract MediaRegistryTest is Test {
    /* MediaRegistry architecture */
    MediaRegistry mediaRegistry;
    address trustedOperator = address(0x123);
    /* CONSTANTS */
    address admin = address(0x999);
    address mockAttribution = address(0x231004);
    string mockUri = "ipfs://bafkreiden6msn3wycwto42hepsri2ztocoh3e36jl5mawvlem2xqkb7ffu";

    // Set up called before each test
    function setUp() public {
        vm.startPrank(trustedOperator);
        mediaRegistry = new MediaRegistry(trustedOperator);  
        vm.stopPrank();
    }    

    function test_trustedCreateToken() public {
        vm.startPrank(trustedOperator);
        mediaRegistry.trustedCreateToken(mockAttribution, admin, mockUri);     
    }  

    /* HELPERS */
}