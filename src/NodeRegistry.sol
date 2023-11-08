// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

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
     * @dev Emit an event when a new schema is registered
     *
     *      Schemas are unique hash identifiers that nodeIds anchor themselves to upon initialization
     *      NodeIds that are initialized without providing an existing schema will be considered invalid
     *
     * @param sender        Address of the account calling `registerSchema()`
     * @param schema        Hash value for the unique schema being registered
     * @param data          Data to associate with the registration of a new schema
     */
    event RegisterSchema(address indexed sender, bytes32 indexed schema, bytes data);

    /**
     * @dev Emit an event when a new node is initialized
     *
     *      NodeIds provide targets for messaging strategies. It is recommended
     *      that all messaging strategies include nodeId as a field to provide
     *      affective filtering of the entire data set produced via the registry
     *
     * @param sender        Address of the account calling `initializeNode()`
     * @param nodeId        NodeId being initialized
     * @param data          Data to associate with the initialization of a new nodeId
     */
    event InitializeNode(address indexed sender, uint256 indexed nodeId, bytes data);

    /**
     * @dev Emit an event when a new update is sent
     *
     *      Updates allow for the transmission of data to existing nodes. The sender field in the
     *      UpdateNode event allows for filtering by accounts such as app-level signers,
     *      while the updateId field allows for a universal-id mechanism to identify
     *      given updates regardless of the nodeId they are targeting
     *
     * @param sender        Address of the account calling `updateNode()`
     * @param updateId      The updateId being generated
     * @param data          Data to transmit in the update
     */
    event UpdateNode(address indexed sender, uint256 indexed updateId, bytes data);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public schemaCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public updateCount;

    //////////////////////////////////////////////////
    // SCHEMA REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function registerSchema(bytes calldata data) external returns (bytes32 schema) {
        // Increments schemaCount before hash generation
        schema = keccak256(abi.encode(block.chainid, address(this), ++schemaCount));
        emit RegisterSchema(msg.sender, schema, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerSchemaBatch(bytes[] calldata datas) external returns (bytes32[] memory schemas) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        schemas = new bytes32[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Increments schemaCount before hash generation
            schemas[i] = keccak256(abi.encode(block.chainid, address(this), ++schemaCount));
            // Emit for indexing
            emit RegisterSchema(sender, schemas[i], datas[i]);
        }
    }

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function initializeNode(bytes calldata data) external returns (uint256 nodeId) {
        // Increments nodeCount before event emission
        nodeId = ++nodeCount;
        emit InitializeNode(msg.sender, nodeId, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function initializeNodeBatch(bytes[] calldata datas) external returns (uint256[] memory nodeIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        nodeIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount before event emission
            emit InitializeNode(sender, nodeIds[i], datas[i]);
        }
    }

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function updateNode(bytes calldata data) external returns (uint256 updateId) {
        // Increments updateCount before event emission
        updateId = ++updateCount;
        emit UpdateNode(msg.sender, updateId, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function updateNodeBatch(bytes[] calldata datas) external returns (uint256[] memory updateIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        updateIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Increment updateCount and copy to return variable
            updateIds[i] = ++updateCount;
            // Emit Message event
            emit UpdateNode(sender, updateIds[i], datas[i]);
        }
    }
}