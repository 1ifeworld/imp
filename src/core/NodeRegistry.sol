// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/**
 * @title NodeRegistry
 * @author Lifeworld
 */
contract NodeRegistry is INodeRegistry {

    // TODO: Update the descriptions for events since they mean different things 
    //      now that some of data has moved into explicit types rather  
    //      than being encoded

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Revert when input arrays dont have the same length
    error Array_Length_Mismatch();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /**
     * @dev Emit an event when a new nodeSchema is registered
     *
     *      nodeSchemas are unique schema identifiers that nodeIds declare as upon registration
     *      NodeIds that are reigstered without providing an existing nodeSchema will be considered invalid
     *
     * @param sender        Address of the account calling `registerNodeSchema()`
     * @param id            Id to associate with call
     * @param nodeSchema    The unique nodeSchema being registered
     * @param data          Data to associate with the registration of a new nodeSchema
     */
    event RegisterNodeSchema(address indexed sender, uint256 indexed id, bytes32 indexed nodeSchema, bytes data);

    /**
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide targets for messaging schemes. It is recommended
     *      that all messaging schemes include nodeId as a field to provide
     *      affective filtering of the entire data set produced via the registry
     *
     * @param sender        Address of the account calling `registerNode()`
     * @param id            Id to be associated with call
     * @param nodeId        NodeId being registered
     * @param nodeType      Type of node being registered
     * @param data          Data to associate with the registration of a new nodeId
     */
    event RegisterNode(
        address sender, uint256 indexed id, uint256 indexed nodeId, bytes32 indexed nodeType, bytes data
    );

    /**
     * @dev Emit an event when a new message is sent
     *
     *      Messages allow for the generic transmission of data. The sender field in the
     *      message event allows for filtering by accounts such as app level signers
     *      while the messageId field allows for a universal-id mechanism to target
     *      given messages regardless of the nodeId they are targeting.
     *
     * @param sender        Address of the account calling `messageNode()`
     * @param id            Id to associate with message
     * @param nodeId        NodeId to target with message
     * @param messageId     The messageId being generated
     * @param data          Data to transmit in the message
     */
    event Message(address sender, uint256 indexed id, uint256 indexed nodeId, uint256 indexed messageId, bytes data);

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
    function registerNodeSchema(uint256 id, bytes calldata data) external returns (bytes32 nodeSchema) {
        // Increments nodeSchemaEntropy before hash generation
        nodeSchema = keccak256(abi.encode(block.chainid, address(this), ++nodeSchemaEntropy));
        emit RegisterNodeSchema(msg.sender, id, nodeSchema, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNodeSchemaBatch(uint256 id, bytes[] calldata datas)
        external
        returns (bytes32[] memory nodeSchemas)
    {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        nodeSchemas = new bytes32[](datas.length);
        for (uint256 i; i < datas.length;) {
            // Increments nodeSchemaEntropy before hash generation
            nodeSchemas[i] = keccak256(abi.encode(block.chainid, address(this), ++nodeSchemaEntropy));
            // Emit for indexing
            emit RegisterNodeSchema(sender, id, nodeSchemas[i], datas[i]);
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
    function registerNode(uint256 id, bytes32 nodeType, bytes calldata data) external returns (uint256 nodeId) {
        // Increments nodeCount before event emission
        nodeId = ++nodeCount;
        emit RegisterNode(msg.sender, id, nodeId, nodeType, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerNodeBatch(uint256 id, bytes32[] calldata nodeTypes, bytes[] calldata datas)
        external
        returns (uint256[] memory nodeIds)
    {
        // Cache msg.sender
        address sender = msg.sender;
        // Cache nodeTypes length
        uint256 quantity = nodeTypes.length;
        // Check input lengths
        if (quantity != datas.length) revert Array_Length_Mismatch();
        // Assign return data length
        nodeIds = new uint256[](quantity);
        for (uint256 i; i < quantity;) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount before event emission
            emit RegisterNode(sender, id, nodeIds[i], nodeTypes[i], datas[i]);
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
    function messageNode(uint256 id, uint256 nodeId, bytes calldata data) external returns (uint256 messageId) {
        // Increments messageCount before event emission
        messageId = ++messageCount;
        emit Message(msg.sender, id, nodeId, messageId, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function messageNodeBatch(uint256 id, uint256[] calldata nodeIds, bytes[] calldata datas)
        external
        returns (uint256[] memory messageIds)
    {
        // Cache msg.sender
        address sender = msg.sender;
        // Cache nodeIds length
        uint256 quantity = nodeIds.length;
        // Check input lengths
        if (quantity != datas.length) revert Array_Length_Mismatch();
        // Assign return data length
        messageIds = new uint256[](quantity);
        for (uint256 i; i < quantity;) {
            // Increment messageCount and copy to return variable
            messageIds[i] = ++messageCount;
            // Emit Message event
            emit Message(sender, id, nodeIds[i], messageIds[i], datas[i]);
            // Cannot realistically overflow
            unchecked { ++i; }
        }
    }
}