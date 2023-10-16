// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title NodeRegistry
 */
contract NodeRegistry {

    event Registration(address indexed sender, uint256 indexed nodeId, bytes data);
    
    event Message(address indexed sender, bytes message);
    event MessageWithIdSpecificNonce(address indexed sender, uint256 indexed nodeId, uint256 indexed nodeIdMessageCount, bytes message);
    event MessageWithGenericNonce(address indexed sender, uint256 indexed messageId, bytes message);

    event BatchMessageWithGenericNonce(address indexed sender, bytes[] messages);
    
    // First node will be 1
    uint256 public nodeCount;
    // Nonce-esque system wide message counter
    uint256 public messageCount;    
    // Nonce-esque nodeId specific message counter
    mapping(uint256 => uint256) public nodeIdMessageCount;

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////    

    // Increments nodeCount and emits generic data/instructions for use in 
    //      offchain node registration systems
    function registerNode(bytes memory data) external {
        // ++x results in nodeCount being incremented before event emission
        emit Registration(msg.sender, ++nodeCount, data);        
    }

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////  

    // Emits generic data/instructions for use in 
    //      offchain message processing systems
    function messageNode(bytes memory data) external {
        emit Message(msg.sender, data);
    }        

    // Increments nodeIdMessageCount and emits generic data/instructions for use in 
    //      offchain message processing systems
    function messageNodeWithIdSpecificNonce(uint256 nodeId, bytes memory data) external {
        // ++x results in nodeIdMessageCount being incremented before event emission
        emit MessageWithIdSpecificNonce(msg.sender, nodeId, ++nodeIdMessageCount[nodeId], data);
    }    

    // Increments messageCount and emits generic data/instructions for use in 
    //      offchain message processing systems
    function messageNodeWithGenericNonce(bytes memory data) external {
        // ++x results in messageCount being incremented before event emission
        emit MessageWithGenericNonce(msg.sender, ++messageCount, data);
    }        

    /* ideas for batching */

    function batchMessageNodeWithGenericNonce_v1(bytes[] memory datas) external {
        for (uint256 i; i < datas.length; ) {
            emit MessageWithGenericNonce(msg.sender, ++messageCount, datas[i]);
            // Cannot realistically overflow
            unchecked {
                ++i;
            }
        }
    }        

    // USAGE
    //      Datas.length will be used by indexers to reconstruct message ids for
    //      Data emitted in batch call
    function batchMessageNodeWithGenericNonce_v2(bytes[] memory datas) external {
        messageCount += datas.length;
        emit BatchMessageWithGenericNonce(msg.sender, datas);
    }      
}