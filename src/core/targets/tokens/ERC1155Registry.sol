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
            uriInfo[cachedCounter] = tokenInputs[i].uri;
            adminInfo[cachedCounter][admin] = true;
            if (tokenInputs[i].salesModule != address(0)) {
                saleInfo[cachedCounter] = tokenInputs[i].salesModule;
                ISalesModule(tokenInputs[i].salesModule).setupToken(sender, cachedCounter, tokenInputs[i].commands);
            }
            emit URI(tokenInputs[i].uri, cachedCounter);
            ids[i] = cachedCounter;
        }
        // Handle system fees
        _handleFees(quantity);
        // Batch mint tokens to sender        
        _batchMint(sender, ids, _single(quantity), new bytes(0));
    }

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    function uri(uint256 id) public view override returns (string memory) {
        return uriInfo[id];
    }

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    function _single(uint256 length) internal pure returns (uint256[] memory array) {
        array = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            array[i] = 1;
        }
        return array;
    }
}


