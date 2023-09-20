// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";

import {IChannelRegistry} from "./interfaces/IChannelRegistry.sol";
import {ChannelRegistryStorage} from "./storage/ChannelRegistryStorage.sol";

import {FeeManager} from "../../../utils/fees/FeeManager.sol";
import {FundsReceiver} from "../../../utils/FundsReceiver.sol";

/**
 * @title ChannelRegistry
 */
contract ChannelRegistry is
    ERC1155,
    ERC1155TokenReceiver,
    ChannelRegistryStorage,
    IChannelRegistry,
    FeeManager,
    FundsReceiver,
    ReentrancyGuard
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
        /* 
            NOTE:
            could potentialyl get rid of this router origin check because the sender
            we are passing in isnt critical to functionality of this function
            it is useful from an activity standpoint tho. the reason sender isnt
            used is because admins are assigned thru data being passed into function
        */ 
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Increment channel counter
        ++channelCounter;
        // Cache channel counter
        uint256 counter = channelCounter;
        // Decode data
        (string memory channelUri, bytes32 merkleRoot, address[] memory admins) =
            abi.decode(data, (string, bytes32, address[]));
        // Set channel non-admin access control
        merkleRootInfo[counter] = merkleRoot;
        // Mint channelId token to channel registry signifying its creation
        // NOTE: confirm that this can't be malciiously transferred thru a fallback attack?
        //      besides that dont believe theres any route that the token could be transferred out
        _mint(address(this), counter, 1, new bytes(0));
        // Set admins for channel
        for (uint256 i; i < admins.length; ) {
            adminInfo[counter][admins[i]] = true;
            // Using unchecked for-loop from solmate
            unchecked {
                ++i;
            }            
        }
        // Emit channel created event
        emit ChannelCreated(sender, counter, channelUri, merkleRoot, admins);
    }

    function deleteChannel(address sender, uint256 channelId) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();       
        // Confirm sender is admin of target channelId
        if (!adminInfo[channelId][sender]) revert No_Access();
        // Check that channel has not been frozen or deleted
        if (balanceOf[address(this)][channelId] != 1) revert Channel_Frozen_Or_Deleted(channelId);         
        // Burn token held by ChannelRegistry
        // NOTE: this will revert if channel has already been deleted since the registry
        // balance will be 0 and cannot burn another token
        _burn(address(this), channelId, 1);
    }

    function freezeChannel(address sender, uint256 channelId) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();       
        // Confirm sender is admin of target channelId
        if (!adminInfo[channelId][sender]) revert No_Access();
        // Check that channel has not been frozen or deleted
        if (balanceOf[address(this)][channelId] != 1) revert Channel_Frozen_Or_Deleted(channelId);        
        // Burn token held by ChannelRegistry
        // NOTE: this will revert if channel has already been deleted since the registry
        // balance will be 0 and cannot burn another token
        _burn(address(this), channelId, 1);
    }    

    function addToChannel(address sender, bytes memory data) external payable nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();        
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, Listing[] memory listings) =
            abi.decode(data, (uint256, bytes32[], Listing[]));        
        // Check that channel has not been frozen or deleted from channel registry
        if (balanceOf[address(this)][channelId] != 1) revert Channel_Frozen_Or_Deleted(channelId);        
        // Grant access to sender if they are an admin or on merkle tree            
        if (!adminInfo[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, merkleRootInfo[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Handle system fees for given listings.length of data
        _handleFees(listings.length);      
        // Emit data for indexing
        emit DataStored(sender, channelId, listings);
    }

    function removeFromChannel(address sender, bytes memory data) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256 channelId, bytes32[] memory merkleProof, uint256[] memory listingIds) =
            abi.decode(data, (uint256, bytes32[], uint256[]));
        // Check that channel has not been frozen or deleted from channel registry
        if (balanceOf[address(this)][channelId] != 1) revert Channel_Frozen_Or_Deleted(channelId);           
        // Grant access to sender if they are an admin or on merkle tree
        if (!adminInfo[channelId][sender]) {
            if (!MerkleProofLib.verify(merkleProof, merkleRootInfo[channelId], keccak256(abi.encodePacked(sender)))) {
                revert No_Access();
            }
        }
        // Emit data for indexing
        // NOTE: Integrated backend solution will only process remove events for valid listingIds removal calls
        //      A valid call is one where:
        //          1. the id lower or equal to the total number of listings broadcasted
        //          2. The sender of the call is either an admin (universl remove access) or the original broadcaster 
        //              of the givenId
        // NOTE: This could also potentially be moved offchain into channelUri as well
        //      but I think theres a case to be made that add + remove should both be onchain events
        emit DataRemoved(sender, channelId, listingIds);
    }  

    function updateAdmins(address sender, uint256 channelId, address[] memory accounts, bool[] memory roles) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();        
        // Check if sender is admin of channelId
        if (!adminInfo[channelId][sender]) revert No_Access();        
        // Check that valid inputs submitted
        if (accounts.length != roles.length) revert Input_Length_Mismatch();
        // Assign admin roles
        for (uint256 i; i < accounts.length; ) {
            adminInfo[channelId][accounts[i]] = roles[i];
            // Using unchecked for-loop from solmate
            unchecked {
                ++i;
            }                  
        }
        emit AdminsUpdated(sender, channelId, accounts, roles);
    }    

    function updateMerkleRoot(address sender, uint256 channelId, bytes32 merkleRoot) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();        
        // Check if sender is admin of channelId
        if (!adminInfo[channelId][sender]) revert No_Access();
        merkleRootInfo[channelId] = merkleRoot;
        emit MerkleRootUpdated(sender, channelId, merkleRoot);
    }    

    function updateUri(address sender, uint256 channelId, string memory channelUri) external nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();        
        // Check that channel has not been frozen or deleted from channel registry
        // NOTE: This check is used in updateUri but not `updateMerkleRoot` or `updateAdmins`
        if (balanceOf[address(this)][channelId] != 1) revert Channel_Frozen_Or_Deleted(channelId);         
        // Check if sender is admin of channelId
        if (!adminInfo[channelId][sender]) revert No_Access();
        emit UriUpdated(sender, channelId, channelUri);
    }

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    function uri(uint256 id) public view override returns (string memory) {
        return "Dont worry about it";
    }    
}