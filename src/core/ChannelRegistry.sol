// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*
    Things to consider

    - converting back into 1155 and minting one token per channelId
        to the channel registry itself
*/

/**
 * @title ChannelRegistry
 */
contract ChannelRegistry {

    event NewChannel(address sender, uint256 id, bytes data);
    event ChannelAction(address sender, bytes action);

    uint256 public channelCounter;

    function newChannel(bytes memory data) external returns (uint256 channelId) {
        /* Safety: idCounter won't realistically overflow. */
        unchecked {        
            /* Incrementing before assignment ensures that first tokenId is 1. */
            channelId = ++channelCounter;
        }           
        // Emit for indexing
        emit NewChannel(msg.sender, channelId, data);        
    }

    function submitChannelAction(bytes memory data) external {
        emit ChannelAction(msg.sender, data);
    }    
}