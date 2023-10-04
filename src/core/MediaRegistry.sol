// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import "sstore2/SSTORE2.sol";

/**
 * @title MediaRegistry
 */
contract MediaRegistry is ERC1155 {
    using ECDSA for bytes32;

    error Not_Trusted_Operator();

    address internal immutable _trustedOperator;
    uint256 public idCounter;
    mapping(uint256 => address) idToAdmin;
    mapping(uint256 => address) idToUri;

    constructor(address trustedOperator) {
        _trustedOperator = trustedOperator;
    }

    function trustedCreateToken(
        address attribution, 
        address admin, 
        string memory mediaUri
    ) external returns (uint256 id) {
        // Confirm transaction coming from trusted operator
        if (msg.sender != _trustedOperator) revert Not_Trusted_Operator();
        // Increment and assign new tokenId
        id = ++idCounter;
        // Assign admin
        idToAdmin[id] = admin; 
        // Assign uri
        idToUri[id] = SSTORE2.write(bytes(mediaUri));
        // Mint new token
        _trustedMint(attribution, id, 1, new bytes(0));
        // Emit for indexing
        emit URI(mediaUri, id);
    }

    function trustedCreateTokens(
        address attribution, 
        address admin, 
        string[] memory mediaUris
    ) external returns (uint256[] memory ids) {
        // Confirm transaction coming from trusted operator
        if (msg.sender != _trustedOperator) revert Not_Trusted_Operator();
        // Cache token quantity
        uint256 quantity = mediaUris.length;
        // Initialize ids array for return
        ids = new uint256[](quantity);
        // Begin for loop
        for (uint256 i; i < quantity; ++i) {
            // Increment and assign new tokenId            
            ids[i] = ++idCounter;
            // Assign admin
            idToAdmin[ids[i]] = admin;            
            // Assign uri
            idToUri[ids[i]] = SSTORE2.write(bytes(mediaUris[i]));
            // Emit for metadata indexing
            emit URI(mediaUris[i], ids[i]);
        }
        // Mint new tokens
        _trustedBatchMint(attribution, ids, _singleton(quantity), new bytes(0));
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    function uri(uint256 id) public view override returns (string memory) {
        return string(SSTORE2.read(idToUri[id]));
    }

    //////////////////////////////////////////////////
    // ERC1155 CUSTOMIZATION
    //////////////////////////////////////////////////

    /* 
        The following internal functions allow for the passing through of an address
        to recieve `attribtution` as currently defined by nft-indexers, which typically
        associate the `operator` of the first `TransferSingle` or `TransferBatch` event
        as the "creator" of the token

        The pass through function can only be called by a designated trustedOperator,
        and a non-trusted version of the function exists as well
    */

    // NOTE: NO ACCESS CONTROL CHECKS
    // ENFORCE ELSEWHERE
    // SHOULD ONLY BE ACCESSIBLE BY _trustedOperator
    function _trustedMint(address attribution, uint256 id, uint256 amount, bytes memory data) internal {
        balanceOf[attribution][id] += amount;

        emit TransferSingle(attribution, address(0), attribution, id, amount);

        require(
            attribution.code.length == 0
                ? attribution != address(0)
                : ERC1155TokenReceiver(attribution).onERC1155Received(attribution, address(0), id, amount, data)
                    == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // NOTE: NO ACCESS CONTROL CHECKS
    // ENFORCE ELSEWHERE
    // SHOULD ONLY BE ACCESSIBLE BY _trustedOperator
    function _trustedBatchMint(
        address attribution,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength;) {
            balanceOf[attribution][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(attribution, address(0), attribution, ids, amounts);

        require(
            attribution.code.length == 0
                ? attribution != address(0)
                : ERC1155TokenReceiver(attribution).onERC1155BatchReceived(attribution, address(0), ids, amounts, data)
                    == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    ////////////////////////////////////////////////////////////
    // HELPERS
    ////////////////////////////////////////////////////////////

    function _singleton(uint256 length) internal pure returns (uint256[] memory array) {
        array = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            array[i] = 1;
        }
        return array;
    }    
}
