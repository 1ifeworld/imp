// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

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

    function writeToChannel(bytes memory data) external {
        emit ChannelAction(msg.sender, data);
    }    

    /*
        DEFINING OFFCHAIN SCHEMA FOR CHANNEL CREATION

        struct ChannelInitData {
            uint256 rId,
            uint256 channelAccessScheme,
            bytes channelAccessData,
            string channelUri
        }

        struct ChannelAccessScheme {
            0: abi.encode(address[] admins, bytes32 merkleRoot);
        }

        how logic works
        - backend picks up NewChannel event
        - backend decodes the data into ChannelInitData
        - ChannelInitData must:
            - include a valid channelAccessScheme
            - include channelAccessData that matches designated channelAccessScheme
            - include a valid channelUri
        - if all the above is true, AND the msg.sender has a valid rId,

        checking for the relationship between rId and Signer. what does that produce? is it a hash?  
                // Decode incoming data
        (uint256 channelId, uint256 action, bytes memory actionData) = abi.decode(data, (uint256, uint256, bytes));
    */

    /*
        NOTE: 
        The registry will maintain a balance of 1 for every channelId
        token created. This will allow us to addListings to channels
        that target the address of the registry + tokenId of the channel
    */    
       

    /*
        NOTE: 

            steps:
            - channel action gets picked up
            - (uint256 channelId, uint256 action, bytes memory actionData) = abi.decode(data, (uint256, uint256, bytes));
            - filter begins
                - has sender paid X fee in Y time
                - does channel id exist?
                - does action exist?
                - does actionData fit scehma for target action?
                - does sender have access control to process channelId + action + actionData


    */

    /*
        [DRAFT] ACTION SCHEMA:

        - DelistChannel
            - actionId: 10
            - actionData: bytes(0) - empty bytes value
            - filter rules:
                - only indexed if the caller is an admin at time of call
                - only indexed indexed if channelId exists
                - irreversible once indexed!
        - UpdateAdmins
            - actionId: 11
            - actionData: abi.encode(address[] admins, uint8[] roles)
            - filter rules:
                - only indexed if channelId is indexed
                - only indexed if the caller is an admin at time of call
                - only indexed if admins.length == roles.length
                - role = 0 means non-admin. role = 1 means admin
        - UpdateMerkleRoot
            - actionId: 12
            - actionData: abi.encode(bytes32 merkleRoot)
            - filter rules:
                - only indexed indexed if channelId exists
                - only indexed if the caller is an admin at time of call
                - merkleRoot = bytes32(zeroValue) means anyone can add listings     
        - UpdateChannelUri
            - actionId: 13
            - actionData: abi.encode(string uri)
            - filter rules:
                - only indexed indexed if channelId exists
                - only indexed if the caller is an admin at time of call
                - will only update uri if target uri returns valid channel uri metadata schema
                - channel uri metadata schema
                    - { name: "", description: "", coverImage: ""}    
        - AddListings
            - actionId: 20
            - actionData: abi.encode(Listing[] listings)
            - filter rules:
                - only indexed indexed if channelId exists
                - only indexed if the caller has access to add listings
                - only indexed if target chainId is supported
                - supported chainIds
                    - 1: ethereum mainnet
                    - 10: optimism mainnet
                    - 7777777: zora mainnet       
        - RemoveListings
            - actionId: 21
            - actionData: abi.encode(uint256[] listingIds)
            - filter rules:
                - only indexed if
                    - only indexed indexed if channelId exists
                    - caller is admin of channel
                    - caller was the person who added target listingId
                    - listingId can be removed
                        id has been emitted + hasn't already been removed
        - SortListings
            - actionId: 22
            - actionData: abi.encode(uint256[] listingIds, uint256[] sortValues)
            - filter rules:
                - only indexed if
                - only indexed indexed if channelId exists
                    - caller is admin of channel
                    - listingId can be sorted
                        - id exists                                                 
    */
}