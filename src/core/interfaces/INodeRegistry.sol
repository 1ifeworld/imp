// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface INodeRegistry {

    // TODO: Update the descriptions for events since they mean different things 
    //      now that some of data has moved into explicit types rather  
    //      than being encoded

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Provides entropy for nodeSchema registrations
     */
    function nodeSchemaEntropy() external view returns (uint256);    

    /**
     * @notice Tracks number of nodes registered
     */
    function nodeCount() external view returns (uint256);

    /**
     * @notice Tracks number of messages sent
     */
    function messageCount() external view returns (uint256);

    //////////////////////////////////////////////////
    // NODE SCHEMA REGISTRATION
    //////////////////////////////////////////////////    

    /**
     * @notice Register a new nodeSchema by incrementing the nodeEntropy and emitting a
     *      unique hash. These hashes can be used to anchor schemas for nodeIds. Callable by anyone
     *
     * @param id          Id to associate with RegisterNodeSchema event
     * @param data        Data to associate with RegisterNodeSchema event
     */
    function registerNodeSchema(uint256 id, bytes calldata data) external returns (bytes32 nodeSchema);    

    /**
     * @notice Register a new nodeSchema by incrementing the nodeEntropy and emitting a
     *      unique hash. These hashes can be used to anchor schemas for nodeIds. Callable by anyone
     *
     * @param id           Id to associate with RegisterNodeSchema event
     * @param datas        Data to associate with RegisterNodeSchema events
     */
    function registerNodeSchemaBatch(uint256 id, bytes[] calldata datas) external returns (bytes32[] memory);  

    //////////////////////////////////////////////////
    // NODE ID REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @notice Register a new node by incrementing the nodeCount and emitting data
     *      in association with the registration event. Callable by anyone.
     *
     * @param id        Id to associate with RegisterNode event
     * @param nodeType  Node type to associate with RegisterNode event
     * @param data      Data to associate with RegisterNode event
     */
    function registerNode(uint256 id, bytes32 nodeType, bytes calldata data) external returns (uint256 nodeId);

    /**
     * @notice Batch version of `registerNode`
     *
     * @param id        Id to associate with RegisterNode event
     * @param datas     Data to associate with RegisterNode events
     */
    function registerNodeBatch(uint256 id, bytes32[] calldata nodetype, bytes[] calldata datas) external returns (uint256[] memory nodeIds);

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////

    /**
     * @notice Message a node by incrementing the messageCount and emitting data
     *      in association with the message event. Callable by anyone.
     *
     * @param id        Id to associate with Message event
     * @param nodeId    NodeId to associate with Message event
     * @param data      Data to associate with Message event
     */
    function messageNode(uint256 id, uint256 nodeId, bytes calldata data) external returns (uint256 messageId);

    /**
     * @notice Batch version of `messageNode`
     *
     * @param id         Id to associate with Message event
     * @param nodeIds    NodeIds to associate with Message event
     * @param datas      Data to associate with each Message event
     */
    function messageNodeBatch(uint256 id, uint256[] calldata nodeIds, bytes[] calldata datas) external returns (uint256[] memory messageIds);
}
