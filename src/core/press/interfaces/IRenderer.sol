// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRenderer {
    /// @notice Initializes setup data in renderer contract
    function initializeWithData(bytes memory data) external;
    /// @notice Returns string press URI from a provided sstore2 pointer
    function renderPressURI(address pointer) external view returns (string memory pressURI);
}