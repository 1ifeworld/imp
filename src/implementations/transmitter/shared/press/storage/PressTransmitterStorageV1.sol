// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// TODO: missing UUPS storage gap?

contract PressTransmitterStorageV1 {
    /**
     * @notice Maps data id to address of original sender
     */
    mapping(uint256 => address) public idOrigin;    
}
