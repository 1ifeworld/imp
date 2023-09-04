// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";

import {ISharedPress} from "../../../../core/press/interfaces/ISharedPress.sol";
import {FeeManager} from "../../../../core/press/fees/FeeManager.sol";
import {IListing} from "../types/IListing.sol";

import {TransferUtils} from "../../../../utils/TransferUtils.sol";
import {Version} from "../../../../utils/Version.sol";
import {FundsReceiver} from "../../../../utils/FundsReceiver.sol";

/**
 * @title SharedListingTransmitter
 */
contract SharedListingTransmitter is
    IListing,
    ISharedPress,
    FeeManager,
    Version(1),
    FundsReceiver,
    ReentrancyGuard,
    Ownable
{
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event ChannelCreated(address creator, uint256 counter, string uri, bytes32 merkleRoot, address[] admins);
    event DataStored(address sender, uint256 channelId, uint256 endingIdCounter, Listing[] listings);

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////

    // Contract wide variables
    address public router;
    uint256 public channelCounter;
    // Channel access control
    mapping(uint256 => bytes32) public channelMerkleRoot;
    mapping(uint256 => mapping(address => bool)) public channelAdmins;
    // Channel id tracking
    mapping(uint256 => uint256) public channelIdCounter;
    mapping(uint256 => address) public channelIdOrigin;

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    error No_Access();
    error Overwrite_Not_Supported();
    error Cant_Remove_Nonexistent_Id();

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////

    constructor(address _router, address _feeRecipient, uint256 _fee) FeeManager(_feeRecipient, _fee) {
        router = _router;
    }

    ////////////////////////////////////////////////////////////
    // CHANNEL INITIALIZATION
    ////////////////////////////////////////////////////////////

    /**
     * @notice Initializes a new channel
     */
    function initialize(address creator, bytes memory data) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Increment channel counter
        ++channelCounter;
        // Cache channel counter
        uint256 counter = channelCounter;
        // Increment channelId counter;
        ++channelIdCounter[counter];
        // Decode init data
        (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Set channel access control
        channelMerkleRoot[counter] = merkleRoot;
        for (uint256 i; i < admins.length; ++i) {
            channelAdmins[counter][admins[i]] = true;
        }
        // Emit channel created event
        emit ChannelCreated(creator, counter, channelUri, merkleRoot, admins);
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // EXTERNAL
    //////////////////////////////

    // function handleSendGeneric(address sender, bytes memory data, uint256 path) external payable {
    //     // Confirm transaction coming from router
    //     if (msg.sender != router) revert Sender_Not_Router();     
    //     // check for path 1
    //     if ()   
    // }

    // // NOTE: no access control, enforce elsewhere
    // function handler_1(address sender, bytes memory data) internal {
    //     // Increment channel counter
    //     ++channelCounter;
    //     // Cache channel counter
    //     uint256 counter = channelCounter;
    //     // Increment channelId counter;
    //     ++channelIdCounter[counter];
    //     // Decode init data
    //     (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
    //         abi.decode(data, (string, bytes32, address[]));
    // }    

    // // NOTE: no access control, enforce elsewhere
    // function handler_2(address sender, bytes memory data) internal {
    //     // Decode incoming data
    //     (uint256 channelId, bytes32[] memory merkleProof, Listing[] memory listings) =
    //         abi.decode(data, (uint256, bytes32[], Listing[]));
    // }

    /* ~~~ Token Data Interactions ~~~ */

    function handleSendV2(address sender, bytes memory data) external payable {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, Listing[] memory listings) =
            abi.decode(data, (uint256, bytes32[], Listing[]));
        // Cache data quantity
        uint256 quantity = listings.length;
        // Grant access to sender if they are an admin or on merkle tree
        if (!channelAdmins[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, channelMerkleRoot[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Store sender + increment id counter for each piece of data
        for (uint256 i; i < quantity; ++i) {
            // Record sender address for given id
            channelIdOrigin[channelIdCounter[channelId]] = sender;
            // Increment channelId counter
            ++channelIdCounter[channelId];
        }
        // Handle system fees for given quantity of data
        _handleFees(quantity);
        // Emit data for indexing
        emit DataStored(
            sender,
            channelId,
            channelIdCounter[channelId],
            listings
        );
    }
}
