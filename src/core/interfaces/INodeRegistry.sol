// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface INodeRegistry {
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Tracks number of nodes registered
     */
    function nodeCount() external view returns (uint256 count);

    /**
     * @notice Tracks number of messages sent
     */
    function messageCount() external view returns (uint256 count);

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @notice Register a new node by incrementing the nodeCount and emitting data
     *      in association with the registration event. Callable by anyone.
     *
     * @param data      Data to associate with Register event
     */
    function registerNode(bytes calldata data) external returns (uint256 nodeId);

    /**
     * @notice Batch version of `registerNode`
     *
     * @param datas     Data to associate with Register events
     */
    function registerNodeBatch(bytes[] calldata datas) external returns (uint256[] memory nodeIds);

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////

    /**
     * @notice Message a node by incrementing the messageCount and emitting data
     *      in association with the message event. Callable by anyone.
     *
     * @param data      Data to associate with Message event
     */
    function messageNode(bytes calldata data) external returns (uint256 nodeId);

    /**
     * @notice Batch version of `messageNode`
     *
     * @param datas     Data to associate with Message events
     */
    function messageNodeBatch(bytes[] calldata datas) external returns (uint256[] memory nodeIds);
}
