// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IListing {
    struct Listing {
        uint128 chainId;
        uint128 tokenId;
        address listingAddress;
        bool hasTokenId;
    }
}
