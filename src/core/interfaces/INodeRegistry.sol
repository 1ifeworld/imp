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
     * @param data Data to associate with registration event
     */
    function registerNode(bytes calldata data) external;

    /**
     * @notice Batch version of `registerNode`
     *
     * @param datas Data to associate with registration events
     */
    function registerNodeBatch(bytes[] calldata datas) external;

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////

    /**
     * @notice Message a node by incrementing the messageCount and emitting data
     *      in association with the message event. Callable by anyone.
     *
     * @param data Data to associate with message event
     */
    function messageNode(bytes calldata data) external;

    /**
     * @notice Batch version of `messageNode`
     *
     * @param datas Data to associate with message events
     */
    function messageNodeBatch(bytes[] calldata datas) external;
}
