// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRenderer {
    /// @notice Initializes setup data in renderer contract
    function initializeWithData(bytes memory data) external;
}