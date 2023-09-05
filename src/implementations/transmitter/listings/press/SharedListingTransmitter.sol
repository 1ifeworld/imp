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
    event DataRemoved(address sender, uint256 channelId, uint256[] ids);

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
    error Id_Doesnt_Exist();

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
        // Increment channelId counter from 0 -> 1;
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
        // Update channelId counter
        channelIdCounter[channelId] = channelIdCounter[channelId] + quantity;
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

    function handleRemoveV2(address sender, bytes memory data) external payable {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, uint256[] memory ids) =
            abi.decode(data, (uint256, bytes32[], uint256[]));
        // Grant access to sender if they are an admin or on merkle tree
        if (!channelAdmins[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, channelMerkleRoot[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // only allow ids removal
        for (uint256 i; i < ids.length; ++i) {
            if (ids[i] > channelIdCounter[channelId]) revert Id_Doesnt_Exist();
        }
        // Emit data for indexing
        emit DataRemoved(
            sender,
            channelId,
            ids
        );
    }    
}
