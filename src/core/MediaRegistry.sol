// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC1155} from "solmate/tokens/ERC1155.sol";

/*
    NOTE: comments on design


*/

/**
 * @title MediaRegistry
 */
contract MediaRegistry is ERC1155 {
    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////    

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////
    

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    // NOTE: needed for compatibility with inherited ERC1155 standard
    function uri(uint256 /* id */) public pure override returns (string memory) {
        return "NOTE: Token URIs not supported in this contract";
    }
}