// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPress1155TypesV1 {
    struct AdvancedSettings {
        /// @notice        
        address fundsRecipient;
        /// @notice        
        uint16 royaltyBPS;
        /// @notice        
        bool transferable;
        /// @notice
        bool fungible;
    }
}