// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/**
 * @title NodeRegistry
 * @author Lifeworld, Co.
 */
contract NodeRegistry is INodeRegistry {

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    /**
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide anchors for messaging schemes. It is recommended
     *      that all messaging schemes include nodeId as a field to provide
     *      affective filtering of the entire data set produced by the registry
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
    function registerNode(bytes calldata data) external {
        // Increments nodeCount before event emission
        emit Register(msg.sender, ++nodeCount, data);        
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNodeBatch(bytes[] calldata datas) external {    
        address sender = msg.sender;
        for (uint256 i; i < datas.length; ) {
            // Increments nodeCount before event emission
            emit Register(sender, ++nodeCount, datas[i]);     
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
    function messageNode(bytes calldata data) external {
        // Increments messageCount before event emission
        emit Message(msg.sender, ++messageCount, data);
    }         

    /**
     * @inheritdoc INodeRegistry
     */
    function messageNodeBatch(bytes[] calldata datas) external {    
        address sender = msg.sender;
        for (uint256 i; i < datas.length; ) {
            // Increments messageCount before event emission
            emit Register(sender, ++messageCount, datas[i]);     
            // Cannot realistically overflow
            unchecked { ++i; }    
        }
    }     
}