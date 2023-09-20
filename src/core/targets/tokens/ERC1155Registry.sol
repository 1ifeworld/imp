// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";

import {IERC1155Registry} from "./interfaces/IERC1155Registry.sol";
import {ISalesModule} from "./interfaces/ISalesModule.sol";
import {ERC1155RegistryStorage} from "./storage/ERC1155RegistryStorage.sol";

import {FeeManager} from "../../../utils/fees/FeeManager.sol";
import {FundsReceiver} from "../../../utils/FundsReceiver.sol";
import {TransferUtils} from "../../../utils/TransferUtils.sol";

/**
 * @title ERC1155Registry
 */
contract ERC1155Registry is
    ERC1155,
    IERC1155Registry,
    ERC1155RegistryStorage,
    FeeManager,
    FundsReceiver,
    ReentrancyGuard,
    Ownable
{
    // New events/storage for draft features

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    struct TokenInputs {
        address salesModule;
        string uri;
        bytes commands;
    }

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////

    constructor(address _router, address _feeRecipient, uint256 _fee) FeeManager(_feeRecipient, _fee) {
        router = _router;
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    // TODO: could pass along desired recipient addres in encoded data
    /*
        NOTE: storage breakdown and room for optimizations
        At the moment, the following data is being stored with each token

        slot 1: uri. the ipfs string uri (66 bytes) is being sstored2 (roughly 50k gas), and then we are
            storing the resulting pointer (22.5k gas). this means storing the uri = ~75k gas. not great
        slot 2: admin. the desired admin address (ability to edit token medata + sale logic) is stored
            for each token id (22.5k gas). unavoidable storage in this shared 1155 route.
        slot 3 (optional): sales strategy. this is an optionally passed sales module that allows you
            to kick off a sale for a token upon its creation (22.5k gas + x gas for necessary init data)

        summary: The above means that right now, ~100k gas must be spent for each token to store its
            uri metadata + admin, on top of the updates that happen in the base 1155 implementation
            regarding user balance storage, token transfer events, etc. The good thing about 1155
            is that the gas costs of the base storage/events are similar for single vs batch minting,
            but the bad part about the additional storage we are adding is that it scales linearly.
    */
    function createTokens(address sender, bytes memory data) external payable nonReentrant {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (address admin, TokenInputs[] memory tokenInputs) = abi.decode(data, (address, TokenInputs[]));  
        // Cache tokenInputs length
        uint256 quantity = tokenInputs.length;
        // Init memory array for mint Ids
        uint256[] memory ids = new uint256[](quantity);
        // Set uri + admin for each new token        
        for (uint256 i; i < quantity; ++i) {
            ++counter;
            uint256 cachedCounter = counter;            
            uriInfo[cachedCounter] = SSTORE2.write(bytes(tokenInputs[i].uri));        
            adminInfo[cachedCounter][admin] = true;
            if (tokenInputs[i].salesModule != address(0)) {
                saleInfo[cachedCounter] = tokenInputs[i].salesModule;
                ISalesModule(tokenInputs[i].salesModule).setupToken(sender, cachedCounter, tokenInputs[i].commands);
                // maybe call this ICollectable instead?
            }
            ids[i] = cachedCounter;
            emit URI(tokenInputs[i].uri, cachedCounter);
        }
        // Handle system fees
        _handleFees(quantity);
        // Batch mint tokens to sender        
        _batchMint(sender, ids, _singleton(quantity), new bytes(0));
    }

    function collect(address recipient, uint256 tokenId, uint256 quantity) external payable nonReentrant {
        // Check if sales module has been registered for this token
        if (saleInfo[tokenId] == address(0)) revert No_Sales_Module_Registered();
        // Cache msg.sender        
        address sender = msg.sender;
        // Get collect rules for given sales module
        // TODO: make sure not having the recipietny in the requestCollect call isnt necessary
        //      could replace everything except tokenId (or at least quantity) with a bytes value
        //      that could make it so the sales logic can process additional commands as well (ex: redemption flows)
        (bool access, uint256 price, address fundsRecipient) = ISalesModule(saleInfo[tokenId]).requestCollect(sender, tokenId, quantity);   
        if (!access) revert No_Collect_Access();             
        if (msg.value != price) revert Incorrect_Msg_Value();
        // Process mint
        _mint(recipient, tokenId, quantity, new bytes(0));
        // Transfer funds to specified tokenId recipient, revert if transfer failed
        if (!TransferUtils.safeSendETH(
            fundsRecipient,
            price, 
            TransferUtils.FUNDS_SEND_NORMAL_GAS_LIMIT
        )) {
            revert ETHTransferFailed(fundsRecipient, price);
        }                              
        // Emit Collected event
        emit Collected(sender, recipient, tokenId, quantity, price);
        /*
            NOTE: for later
            potentially add a check here to refund eth sent for collect if hasnt
            been fully sent yet. this would protect from ppl sending funds to 
            collect a tokenId whose recipient address is address(0)
        */
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    function uri(uint256 id) public view override returns (string memory) {
        return string(SSTORE2.read(uriInfo[id]));
    }

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    function _singleton(uint256 length) internal pure returns (uint256[] memory array) {
        array = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            array[i] = 1;
        }
        return array;
    }

    ////////////////////////////////////////////////////////////
    // HELPERS
    ////////////////////////////////////////////////////////////

    // Withdraw ETH accidentally sent to address
    function withdraw(address recipient) public payable onlyOwner {
        uint256 registryEthBalance = address(this).balance;
        if (!TransferUtils.safeSendETH(
            recipient, 
            registryEthBalance, 
            TransferUtils.FUNDS_SEND_NORMAL_GAS_LIMIT
        )) {
            revert ETHTransferFailed(recipient, registryEthBalance);
        }        
    }    
}


