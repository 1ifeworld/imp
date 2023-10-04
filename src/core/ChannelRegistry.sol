// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

/**
 * @title ChannelRegistry
 */
contract ChannelRegistry is ERC1155, ERC1155TokenReceiver {
    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event NewChannel(address sender, uint256 id, bytes data);
    event ChannelAction(address sender, bytes actionData);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////    

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////

    uint256 public channelCounter;

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    /*
        DEFINING OFFCHAIN SCHEMA FOR CHANNEL CREATION

        struct ChannelInitData {
            uint256 rId,
            bytes rIdOwnershipProof,
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
    */

    function newChannel(bytes memory data) external {
        // Increment and assign channelCounter
        uint256 id = ++channelCounter;
        // Mint channelId token to registry
        _mint(address(this), id, 1, new bytes(0));
        // Emit for indexing
        emit NewChannel(msg.sender, id, data);        
    }

    /*
        NOTE: 
        The registry will maintain a balance of 1 for every channelId
        token created. This will allow us to addListings to channels
        that target the address of the registry + tokenId of the channel
    */
    function newChannel(bytes memory data) external {
        // Increment channel counter
        ++channelCounter;
        // Decode data
        (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Mint channelId token to registry
        // NOTE: this costs as implemented roughtly ~27k gas
        _mint(address(this), channelCounter, 1, new bytes(0));        
        // Emit for indexing
        emit NewChannel(msg.sender, channelCounter, channelUri, merkleRoot, admins);
    }

    function writeToChannel(bytes memory data) external payable {
        // Decode incoming data
        (uint256 channelId, uint256 action, bytes memory actionData) = abi.decode(data, (uint256, uint256, bytes));
        // Emit for indexing
        emit ChannelAction(
            msg.sender,
            channelId,
            action,
            actionData
        );
    }    

    function writeToChannel_2(bytes memory data) external payable {
        // Decode incoming data
        (uint256 channelId, bytes memory action) = abi.decode(data, (uint256, bytes));
        // Emit for indexing
        emit ChannelAction_2(
            msg.sender,
            channelId,
            action
        );
    }     

    function writeToChannel_3(bytes calldata data) external payable {
        // Emit for indexing
        emit ChannelAction(
            msg.sender,
            data
        );
    }             

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
        NOTE:
        This version of the function lets us also provide a smart contract wallet to abstract
        user txns through IF they happen to not have a smart wallet themselves.
        A similar function wille exist on the 1155 registry, which is what will let us bundle
        createToken + writeToChannel actions together in case of user not already having a 
        smart contract wallet to facilitate txn bundling


        Newer NOTE:
        we might not need the router version because thers no need for bundle txns
        if River wallet in server is processing txns on behalf of users who have delegated?
        can just call multiple txns in a row?
    */
    function writeToChannelViaRouter(address sender, bytes memory data) external {
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, uint256 action, bytes memory actionData) = abi.decode(data, (uint256, uint256, bytes));
        // Emit for indexing
        emit ChannelAction(
            sender,
            channelId,
            action,
            actionData
        );
    }        

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

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    // NOTE: needed for compatibility with inherited ERC1155 standard
    function uri(uint256 /* id */) public pure override returns (string memory) {
        return "NOTE: Token URIs not supported in this contract";
    }
}