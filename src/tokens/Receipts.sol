// SPDX-License-Identifier: GNU
pragma solidity 0.8.21;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @title Receipts
 * @author Lifeworld
 */
contract Receipts is ERC721, Ownable {
    
    // Token id counter
    uint256 counter;

    constructor(address owner) ERC721("Receipts", "LWR") {
        transferOwnership(owner);
    }

    function mint(address to, uint256 amount) onlyOwner public {
        ++counter;
        _mint(to, amount);
    }

    function tokenURI(uint256 /*id */) public pure override returns (string memory) {
        return "ipfs://bafkreiegagoiqojlvbd6zlbiwbs7cbe4gzbefrbczdsenyljmevea54xwy";
    }
}