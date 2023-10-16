// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title NodeRegistry
 */
contract NodeRegistry {

    event Registration(address indexed sender, uint256 indexed nodeId, bytes data);
    event Message(address indexed sender, bytes message);
    event MessageWithNonce(address indexed sender, uint256 indexed nodeId, uint256 indexed nodeIdMessageCount, bytes message);
    
    // First node will be 1
    uint256 public nodeCount;
    // Nonce-esque nodeId specific message tracker
    mapping(uint256 => uint256) public nodeIdMessageCount;

    // Increments nodeCount and emits generic data/instructions for use in 
    //      offchain node registration systems
    function registerNode(bytes memory data) external {
        // ++x results in nodeCount being incremented before event emission
        emit Registration(msg.sender, ++nodeCount, data);        
    }

    function messageNode(bytes memory data) external {
        emit Message(msg.sender, data);
    }        

    // Increments nodeIdMessageCount and emits generic data/instructions for use in 
    //      offchain message processing systems
    function messageNodeWithNonce(uint256 nodeId, bytes memory data) external {
        // ++x results in nodeIdMessageCount being incremented before event emission
        emit MessageWithNonce(msg.sender, nodeId, ++nodeIdMessageCount[nodeId], data);
    }    
}