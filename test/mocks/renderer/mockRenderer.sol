// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRenderer} from "../../../src/core/press/renderer/IRenderer.sol";

contract MockRenderer is IRenderer {

    // Mapping to keep track of initialized contracts
    mapping(address => bool) public isInitialized;

    function initializeWithData(bytes memory data) external {
        isInitialized[msg.sender] = true;
    }
}