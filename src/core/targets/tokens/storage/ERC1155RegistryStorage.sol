// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ERC1155RegistryStorage {
    // Constants
    /* slot 1 */
    uint256 public constant ERC1155_REGISTRY_VERSION = 1;
    // Contract wide variables
    /* slot 2 */
    address public router;
    uint96 public counter;
    /* slot 3? */
    mapping(uint256 => address) public uriInfo;
    /* slot 4? */
    mapping(uint256 => mapping(address => bool)) adminInfo;    
    /* slot 5? */
    mapping(uint256 => address) saleInfo;    
    /* slot 6? */
    mapping(uint256 => uint256) supplyInfo;
}
