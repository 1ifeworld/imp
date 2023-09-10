// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";

import {IChannelRegistry} from "./interfaces/IChannelRegistry.sol";
import {IListing} from "./interfaces/IListing.sol";
import {ChannelRegistryStorage} from "./storage/ChannelRegistryStorage.sol";
import {FeeManager} from "../fees/FeeManager.sol";

import {TransferUtils} from "../../../utils/TransferUtils.sol";
import {FundsReceiver} from "../../../utils/FundsReceiver.sol";

/**
 * @title ChannelRegistry
 */
contract ChannelRegistry is
    ChannelRegistryStorage,
    IChannelRegistry,
    FeeManager,
    FundsReceiver,
    ReentrancyGuard,
    Ownable
{
    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////

    constructor(address _router, address _feeRecipient, uint256 _fee) FeeManager(_feeRecipient, _fee) {
        router = _router;
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    function newChannel(address sender, bytes memory data) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Increment channel counter
        ++channelCounter;
        // Cache channel counter
        uint256 counter = channelCounter;
        // Decode data
        (string memory uri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Set channel access control
        merkleRootInfo[counter] = merkleRoot;
        for (uint256 i; i < admins.length; ++i) {
            adminInfo[counter][admins[i]] = true;
        }
        // Emit channel created event
        emit ChannelCreated(sender, counter, uri, merkleRoot, admins);
    }

    function addToChannel(address sender, bytes memory data) external payable nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, Listing[] memory listings) =
            abi.decode(data, (uint256, bytes32[], Listing[]));
        // Grant access to sender if they are an admin or on merkle tree
        if (!adminInfo[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, merkleRootInfo[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Update broadcastCounter for given channelId
        broadcastCounter[channelId] += listings.length;
        // Handle system fees for given listings.length of data
        _handleFees(listings.length);
        // Emit data for indexing
        emit DataStored(sender, channelId, broadcastCounter[channelId], listings);
    }

    function removeFromChannel(address sender, bytes memory data) external payable nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, uint256[] memory broadcastIds) =
            abi.decode(data, (uint256, bytes32[], uint256[]));
        // Grant access to sender if they are an admin or on merkle tree
        if (!adminInfo[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, merkleRootInfo[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Prevent removal emission of non-existent ids
        for (uint256 i; i < broadcastIds.length; ++i) {
            if (broadcastIds[i] > broadcastCounter[channelId]) revert Id_Doesnt_Exist();
        }
        // Emit data for indexing
        emit DataRemoved(sender, channelId, broadcastIds);
    }
}