// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* woah */

import {IListing} from "./IListing.sol";

interface IChannelRegistry is IListing {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event ChannelCreated(address sender, uint256 counter, string uri, bytes32 merkleRoot, address[] admins);    
    event DataStored(address sender, uint256 channelId, Listing[] listings);
    event DataRemoved(address sender, uint256 channelId, uint256[] ids);
    event UriUpdated(address sender, uint256 channelId, string uri);
    event MerkleRootUpdated(address sender, uint256 channelId, bytes32 merkleRoot);
    event AdminsUpdated(address sender, uint256 channelId, address[] accounts, bool[] roles);     

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    error No_Access();
    error Overwrite_Not_Supported();
    error Cant_Remove_Nonexistent_Id();
    error Id_Doesnt_Exist();
    error Sender_Not_Router();
    error Input_Length_Mismatch();
    error Channel_Frozen_Or_Deleted(uint256);

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new channel
     */
    function newChannel(address sender, bytes memory data) external;

    /**
     * @notice Deletes channel from registry
     */
    function deleteChannel(address sender, uint256 channelId) external;

    /**
     * @notice Freezes channel from further actions
     */
    function freezeChannel(address sender, uint256 channelId) external;

    /**
     * @notice Adds new data to channel
     */
    function addToChannel(address sender, bytes memory data) external payable;

    /**
     * @notice Removes data from channel
     */
    function removeFromChannel(address sender, bytes memory data) external;

    /**
     * @notice
     */  
    function updateAdmins(address sender, uint256 channelId, address[] memory accounts, bool[] memory roles) external;

    /**
     * @notice
     */
    function updateMerkleRoot(address sender, uint256 channelId, bytes32 merkleRoot) external;    

    /**
     * @notice
     */
    function updateUri(address sender, uint256 channelId, string memory uri) external;    
}
