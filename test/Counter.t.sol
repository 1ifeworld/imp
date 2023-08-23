// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {

    Counter counter;

    function setUp() public {
        counter = new Counter();
    }
    
    address constant head = address(0x1);

    function test_transmit() public {
        Counter.Listing[] memory listings = new Counter.Listing[](1);
        listings[0] = Counter.Listing({
            chainId: 1,
            tokenId: 1,
            listingAddress: address(0x123),
            hasTokenId: true
        });        
        bytes memory data = abi.encode(listings);

        vm.prank(head);
        counter.transmitData(head, data);
    }
}
