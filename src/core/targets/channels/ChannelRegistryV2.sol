// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {IChannelRegistry} from "./interfaces/IChannelRegistry.sol";
import {IListing} from "./interfaces/IListing.sol";
import {ChannelRegistryStorage} from "./storage/ChannelRegistryStorage.sol";

import {FeeManager} from "../../../utils/fees/FeeManager.sol";
import {FundsReceiver} from "../../../utils/FundsReceiver.sol";

/**
 * @title ChannelRegistryV2
 */
contract ChannelRegistryV2 is
    ERC1155,
    ERC1155TokenReceiver,
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
        (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Set channel access control
        merkleRootInfo[counter] = merkleRoot;
        // Mint admin tokens
        /* 
            NOTE:
            Might want to add an extra mint to the registry addres itself
            This would make it so that even if all admins have burned their tokens,
            The channelId can still be picked up by indexing transfer events since
            at least token id will always exist held by the registry.
            Adds ~23k gas to update balances for additional receiever.

            _mint(address(this), counter, 1, new bytes(0));
        */
        _mint(address(this), counter, 1, new bytes(0));

        for (uint256 i; i < admins.length; ) {
            _mint(admins[i], counter, 1, new bytes(0));
            // Using unchecked for-loop from solmate
            unchecked {
                ++i;
            }            
        }
        // Emit channel created event
        // TODO: can remove admins emissions since will be picked up by 1155 token transfer events
        emit ChannelCreated(sender, counter, channelUri, merkleRoot, admins);
    }

    /*
        NOTE:
        Would potentially need to add a guard in channel creation flow + 
        update channels flow that the registry can not be an admin itself
        to ensure that only oen token per channel can be held by regsitry
    */
    function deleteChannel(address sender, uint256 channelId) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();       
        // Confirm sender is admin of target channelId
        if (balanceOf[sender][channelId] == 0) revert No_Access();
        // Burn token held by ChannelRegistry
        _burn(address(this), channelId, 1);
    }

    function addToChannel(address sender, bytes memory data) external payable nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, Listing[] memory listings) =
            abi.decode(data, (uint256, bytes32[], Listing[]));
        // Grant access to sender if they are an admin or on merkle tree    
        /*
            Could add an SLOAD here that checks if the registry token is stil held
            by the channel registry. After that this function would always revert.
            Could also just add into the backend schema that events in a channel after
            The channelId token has been burnt should not be processed to save the gas
            of looking up the registry balance
        */    
        if (balanceOf[sender][channelId] == 0) {
            if (!MerkleProofLib.verify(merkleProof, merkleRootInfo[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Handle system fees for given listings.length of data
        _handleFees(listings.length);
        // Update broadcastCounter for given channelId
        broadcastCounter[channelId] += listings.length;        
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
        if (balanceOf[sender][channelId] == 0) {
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

    function updateUri(address sender, uint256 channelId, string memory channelUri) external {
        if (balanceOf[sender][channelId] == 0) revert No_Access();
        emit UriUpdated(sender, channelId, channelUri);
    }

    function updateMerkleRoot(address sender, uint256 channelId, bytes32 merkleRoot) external {
        if (balanceOf[sender][channelId] == 0) revert No_Access();
        merkleRootInfo[channelId] = merkleRoot;
        emit MerkleRootUpdated(sender, channelId, merkleRoot);
    }

    function updateAdmins(address sender, uint256 channelId, address[] memory accounts, bool[] memory flags) external {
        if (balanceOf[sender][channelId] == 0) revert No_Access();
        if (accounts.length != flags.length) revert Input_Length_Mismatch();
        for (uint256 i; i < accounts.length; ++i) {
            if (flags[i]) {
                _mint(accounts[i], channelId, 1, new bytes(0));
            } else {
                _burn(accounts[i], channelId, 1);
            }
        }
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    function uri(uint256 id) public view override returns (string memory) {
        return "Dont worry about it";
    }    

    ////////////////////////////////////////////////////////////
    // OVERRIDES
    ////////////////////////////////////////////////////////////

    /*
        NOTE:
        There are no before/after transfer hooks in the solmate 1155 impl.
        To implement non-transferable token functionality, you can override the
        `safeTransferFrom` and `safeBatchTransferFrom` functions.
    */

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        revert Admin_Tokens_Not_Transferable();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        revert Admin_Tokens_Not_Transferable();
    }
}


