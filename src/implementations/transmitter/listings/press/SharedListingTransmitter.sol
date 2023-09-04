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

    event ChannelCreated(address creator, uint256 counter, bytes32 channelHash, string uri, bytes32 merkleRoot, address[] admins);
    event DataStored(address sender, bytes32 channelHash, uint256[] ids, Listing[] listings);

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////

    // Contract wide variables
    address public router;
    uint256 public channelCounter;
    mapping(uint256 => bytes32) channelHash;
    // Channel access control
    mapping(bytes32 => bytes32) public channelMerkleRoot;
    mapping(bytes32 => mapping(address => bool)) public channelAdmins;
    // Channel id tracking
    mapping(bytes32 => uint256) public channelIdCounter;
    mapping(bytes32 => address) public channelIdOrigin;

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
        // Assign unique hash to channel        
        bytes32 localHash = keccak256(abi.encodePacked(address(this), counter));
        channelHash[counter] = localHash;
        // Increment channelId counter;
        ++channelIdCounter[localHash];
        // Decode init data
        (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Set channel access control
        channelMerkleRoot[localHash] = merkleRoot;
        for (uint256 i; i < admins.length; ++i) {
            channelAdmins[localHash][admins[i]] = true;
        }
        // Emit channel created event
        emit ChannelCreated(creator, counter, localHash, channelUri, merkleRoot, admins);
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // EXTERNAL
    //////////////////////////////

    /* ~~~ Token Data Interactions ~~~ */

    function handleSendV2(address sender, bytes memory data) external payable {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (bytes32 channelHash, bytes32[] memory merkleProof, Listing[] memory listings) =
            abi.decode(data, (bytes32, bytes32[], Listing[]));
        // Cache data quantity
        uint256 quantity = listings.length;
        // Initialize ids memory array for emission
        uint256[] memory ids = new uint256[](quantity);
        // Grant access to sender if they are an admin or on merkle tree
        if (!channelAdmins[channelHash][sender]) {
            if (!MerkleProofLib.verify(merkleProof, channelMerkleRoot[channelHash], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Store sender + increment id counter for each piece of data
        for (uint256 i; i < quantity; ++i) {
            // Cache value of settings.counter
            uint256 localCounter = channelIdCounter[channelHash];
            // Update function id memory array for return
            ids[i] = localCounter;
            // Record sender address for given id
            channelIdOrigin[channelHash] = sender;
            // Increment channelId counter
            ++channelIdCounter[channelHash];
        }
        // Handle system fees for given quantity of data
        _handleFees(quantity);
        // Emit data for indexing
        emit DataStored(
            sender,
            channelHash,
            ids,
            listings
        );
    }
}
