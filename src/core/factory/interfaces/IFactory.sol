// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFactory {
    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice Deploys and initializes new press
    function createPress(address sender, bytes memory init) external returns (address, address);
}
