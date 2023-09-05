// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* woah */

interface ISharedPress {

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    /// @notice Error when msg.sender is not the stored database impl
    error Sender_Not_Router();
    /// @notice Error when inputting arrays with non matching length
    error Input_Length_Mismatch();
    /// @notice
    error Incorrect_Msg_Value();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Initializes a new channel
     */
    function initialize(address creator, bytes memory data) external;    

    /**
     * @notice Processes data sent to channel
     */
    function handleSendV2(address sender, bytes memory data) external payable;
    
}