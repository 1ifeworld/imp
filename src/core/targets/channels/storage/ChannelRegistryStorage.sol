// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ChannelRegistryStorage {
    /// @notice 
    uint256 public constant CHANNEL_REGISTRY_VERSION = 1;
    /// @notice 
    uint256 public channelCounter;
    /// @notice 
    address public router;    
    /// @notice Non-admin access control basis for channels
    mapping(uint256 => bytes32) public merkleRootInfo;
    /// @notice Admin accessc control basis for channels
    mapping(uint256 => mapping(address => bool)) public adminInfo;
}
