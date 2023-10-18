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
     * @dev Emit an event when a new nodeSchema is registered
     *
     *      nodeSchemas are unique schema identifiers that nodeIds declare as upon registration
     *      NodeIds that are reigstered without providing an existing nodeSchema will be considered invalid
     *
     * @param sender            Address of the account calling `registerNodeSchema()`
     * @param nodeSchema        The unique nodeSchema being registered
     * @param data              Data to associate with the registration of a new nodeSchema
     */
    event RegisterNodeSchema(address indexed sender, bytes32 nodeSchema, bytes data);    

    /**
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide targets for messaging schemes. It is recommended
     *      that all messaging schemes include nodeId as a field to provide
     *      affective filtering of the entire data set produced via the registry
     *
     * @param sender        Address of the account calling `registerNode()`
     * @param nodeId        The nodeId being registered
     * @param data          Data to associate with the registration of a new nodeId
     */
    event RegisterNode(address indexed sender, uint256 indexed nodeId, bytes data);

    /**
     * @dev Emit an event when a new message is sent
     *
     *      Messages allow for the generic transmission of data. The sender field in the
     *      message event allows for filtering by accounts such as app level signers
     *      while the messageId field allows for a universal-id mechanism to target 
     *      given messages regardless of the nodeId they are targeting.
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
    uint256 public nodeSchemaEntropy;
    
    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public messageCount;    

    //////////////////////////////////////////////////
    // NODE SCHEMA REGISTRATION
    //////////////////////////////////////////////////    

    /**
     * @inheritdoc INodeRegistry
     */    
    function registerNodeSchema(bytes calldata data) external returns (bytes32 nodeSchema) {
        // Increments nodeSchemaEntropy before hash generation
        nodeSchema = keccak256(abi.encode(block.chainid, address(this), ++nodeSchemaEntropy));
        emit RegisterNodeSchema(msg.sender, nodeSchema, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */    
    function registerNodeSchemaBatch(bytes[] calldata datas) external returns (bytes32[] memory nodeSchemas) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        nodeSchemas = new bytes32[](datas.length);     
        for (uint256 i; i < datas.length; ) {   
            // Increments nodeSchemaEntropy before hash generation
            nodeSchemas[i] = keccak256(abi.encode(block.chainid, address(this), ++nodeSchemaEntropy));
            // Emit for indexing
            emit RegisterNodeSchema(sender, nodeSchemas[i], datas[i]);       
            // Cannot realistically overflow
            unchecked { ++i; }    
        }            
    }    

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////   

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNode(bytes calldata data) external returns (uint256 nodeId) {
        // Increments nodeCount before event emission
        nodeId = ++nodeCount;
        emit RegisterNode(msg.sender, nodeId, data);        
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
            emit RegisterNode(sender, nodeIds[i], datas[i]);     
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

/*
    How to use the node registry for your app

    - NodeRegistry deployed
    - App operators register as many node types as they need for app
    - App operators provide initial schema for how node registration + messaging will work
        for the nodeSchema(s) they will be supporting
    - App operators (and users themselves if applicable) register nodeIds themselves,
        making sure to assign the desired nodeSchema to each new nodeId 
    - App users send messages (themselves or via delegated operator) to target nodes,
        making sure to structure messages in the format that the nodeSchema specifies as 
        laid out by opeartors
*/