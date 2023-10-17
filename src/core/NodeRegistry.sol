// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/**
 * @title NodeRegistry
 * @author Lifeworld
 */
contract NodeRegistry is INodeRegistry {

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    /**
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide targets for messaging schemes. It is recommended
     *      that all messaging schemes include nodeId as a field to provide
     *      affective filtering of the entire data set produced via the registry
     *
     * @param sender        Address of the account calling `registerNode()`
     * @param nodeId        The nodeId being registered
     * @param data          Data to associate with the registration of a new node
     */
    event Register(address indexed sender, uint256 indexed nodeId, bytes data);

    /**
     * @dev Emit an event when a new message is sent
     *
     *      Messages allow for the generic transmission of data. The sender field in the
     *      message event allows for filtering by accounts such as app level signers
     *      while the messageId field allows for a universal-id mechanism to target 
     *      given messages regardless of the nodeId they are targeting. See 
     *      `OFFCHAIN_MSG_SCHEMA.MD` for an example of structuring the data field
     *
     * @param sender        Address of the account calling `messageNode()`
     * @param messageId     The messageId being generated
     * @param data          Data to transmit in the message
     */
    event Message(address indexed sender, uint256 indexed messageId, bytes data);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////        

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public messageCount;    

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////    

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNode(bytes calldata data) external returns (uint256 nodeId) {
        // Increments nodeCount before event emission
        nodeId = ++nodeCount;
        emit Register(msg.sender, ++nodeId, data);        
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNodeBatch(bytes[] calldata datas) external returns (uint256[] memory nodeIds) {    
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        nodeIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount before event emission
            emit Register(sender, nodeIds[i], datas[i]);     
            // Cannot realistically overflow
            unchecked { ++i; }    
        }
    }

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////        

    /**
     * @inheritdoc INodeRegistry
     */
    function messageNode(bytes calldata data) external returns (uint256 messageId) {
        // Increments messageCount before event emission
        messageId = ++messageCount;
        emit Message(msg.sender, messageId, data);
    }         

    /**
     * @inheritdoc INodeRegistry
     */
    function messageNodeBatch(bytes[] calldata datas) external returns (uint256[] memory messageIds) {    
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        messageIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ) {
            // Increment messageCount and copy to return variable
            messageIds[i] = ++messageCount; 
            // Emit Message event
            emit Message(sender, messageIds[i], datas[i]);     
            // Cannot realistically overflow
            unchecked { ++i; }    
        }
    }         
}