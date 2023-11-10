// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface INodeRegistry {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Provides entropy for nodeSchema registrations
     */
    function schemaCount() external view returns (uint256);    

    /**
     * @notice Tracks number of nodes registered
     */
    function nodeCount() external view returns (uint256);

    /**
     * @notice Tracks number of updates sent
     */
    function updateCount() external view returns (uint256);

    //////////////////////////////////////////////////
    // CHEMA REGISTRATION
    //////////////////////////////////////////////////    

    /**
     * @notice Register a new schema by incrementing the schemaCount and emitting a
     *         unique hash of it. These hashes can be used to anchor schemas for nodeIds
     *
     * @dev Callable by anyone
     *
     * @param data          Data to associate with RegisterSchema event
     */
    function registerSchema(bytes calldata data) external returns (bytes32);    

    /**
     * @notice Register new schemas by incrementing the schemaCount and emitting a
     *         unique hashes of it. These hashes can be used to anchor schemas for nodeIds
     *
     * @dev Callable by anyone
     *
     * @param datas         Data to associate with RegisterSchema events
     */
    function registerSchemaBatch(bytes[] calldata datas) external returns (bytes32[] memory);  

    //////////////////////////////////////////////////
    // NODE INITIALIZATION
    //////////////////////////////////////////////////

    /**
     * @notice Initialize a new node by incrementing the nodeCount and emitting data
     *         in association with the initialization event
     *
     * @dev Callable by anyone
     *
     * @param data          Data to associate with InitializeNode event
     */
    function initializeNode(bytes calldata data) external returns (uint256);

    /**
     * @notice Batch version of `initializeNode`
     *
     * @param datas         Data to associate with InitializeNode events
     */
    function initializeNodeBatch(bytes[] calldata datas) external returns (uint256[] memory);

    //////////////////////////////////////////////////
    // NODE UPDATES
    //////////////////////////////////////////////////

    /**
     * @notice Update a node by incrementing the updateCount and emitting data
     *         in association with the update event 
     * @dev Callable by anyone
     *
     * @param data          Data to associate with UpdateNode event
     */
    function updateNode(bytes calldata data) external returns (uint256);

    /**
     * @notice Batch version of `updateNode`
     *
     * @param datas         Data to associate with each UpdateNode event
     */
    function updateNodeBatch(bytes[] calldata datas) external returns (uint256[] memory);
}
