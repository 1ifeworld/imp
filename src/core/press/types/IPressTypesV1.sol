// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPressTypesV1 {
    struct Settings {
        /// @notice Counter for token storage
        uint256 counter;
        /// @notice Address of the logic contract
        address logic;
        /// @notice Address of the renderer contract
        address renderer;      
    }    
}