// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ChannelRegistryStorageV2 {
    // Constants
    uint256 public constant CHANNEL_REGISTRY_VERSION = 1;
    // Contract wide variables
    address public router;
    uint256 public channelCounter;
    // Broadcast tracking
    mapping(uint256 => uint256) public broadcastCounter;
    // Channel access control
    mapping(uint256 => bytes32) public merkleRootInfo;
}
