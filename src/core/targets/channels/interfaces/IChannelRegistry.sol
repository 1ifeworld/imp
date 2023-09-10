// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* woah */

import {IListing} from "./IListing.sol";

interface IChannelRegistry is IListing {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event ChannelCreated(address sender, uint256 counter, string uri, bytes32 merkleRoot, address[] admins);
    event DataStored(address sender, uint256 channelId, uint256 endingIdCounter, Listing[] listings);
    event DataRemoved(address sender, uint256 channelId, uint256[] ids);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    error No_Access();
    error Overwrite_Not_Supported();
    error Cant_Remove_Nonexistent_Id();
    error Id_Doesnt_Exist();
    error Sender_Not_Router();
    error Input_Length_Mismatch();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new channel
     */
    function newChannel(address sender, bytes memory data) external;

    /**
     * @notice Adds new data to channel
     */
    function addToChannel(address sender, bytes memory data) external payable;
}
