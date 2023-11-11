// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface INodeRegistry {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Tracks number of nodes registered
     */
    function nodeCount() external view returns (uint256);

    //////////////////////////////////////////////////
    // REGISTER
    //////////////////////////////////////////////////

    /**
     * @notice Initialize a new node by incrementing the nodeCount and emitting data
     *         in association with the initialization event
     * 
     * @dev Callable by anyone
     *
     * @param schema        Schema initialize node as
     * @param messages      Messages to send to initialized node
     */
    function register(bytes32 schema, bytes[] calldata messages) external returns (uint256);

    /**
     * @notice Batch version of `register`
     *
     * @dev Will revert messages.length < schemas.length !!
     *
     * @param schemas       Schemas to register nodes as
     * @param messages      Messages to send to registered nodes
     */
    function registerBatch(bytes32[] calldata schemas, bytes[][] calldata messages) external returns (uint256[] memory);

    //////////////////////////////////////////////////
    // UPDATE
    //////////////////////////////////////////////////

    /**
     * @notice Update a node by emitting data in association with a given nodeId
     *
     * @dev Callable by anyone
     *
     * @param nodeId        Id of node to target
     * @param messages      Messages to send to target node
     */
    function update(uint256 nodeId, bytes[] calldata messages) external;

    /**
     * @notice Batch version of `update`
     *
     * @dev Will revert messages.length < schemas.length !!
     *
     * @param nodeIds       Ids of nodes to target
     * @param messages      Messages to send to target nodes
     */
    function updateBatch(uint256[] calldata nodeIds, bytes[][] calldata messages) external;
}
