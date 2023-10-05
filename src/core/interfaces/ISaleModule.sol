// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISaleModule {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    // event UriUpdated(address sender, uint256 channelId, string uri);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    // error Sender_Not_Router();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    // /**
    //  * @notice Creates a new channel
    //  */
    // function newChannel(address sender, bytes memory data) external;
    function setupSale(address sender, uint256 cachedCounter, bytes memory commands) external;

    function requestCollect(address sender, uint256 tokenId, uint256 quantity) external returns (bool, uint256, address);
}