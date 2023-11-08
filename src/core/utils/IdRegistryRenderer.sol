// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IIdRenderer} from "../interfaces/IIdRenderer.sol";

/// TODO: bump to sol 0.8.22
/// TODO: add ability to update metadata scheme

/**
 * @title IdRegistryRenderer
 * @author Lifeworld
 */
contract IdRegistryRenderer is IIdRenderer {

    string public constant tokenUriReturn = "https://arweave.net/fz1j_1tc8l9WWcoACYaGDWRkOveb1h-bKK389w-vWrE";
    string public constant contractUriReturn = "ipfs://QmUzAt4dBhkZk4uZ3JZh9n36Mh4ivmfs6rVXbm56pLMhZz";

    function tokenURI(uint256 /* id */) public pure override returns (string memory) {
        return tokenUriReturn;
    }    

    function contractURI() public pure returns (string memory) {
        return contractUriReturn;
    }    
}