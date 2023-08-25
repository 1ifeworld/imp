// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* woah */

interface IPress {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

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

    //////////////////////////////
    // WRITE
    //////////////////////////////
    function updatePressData(address press, bytes memory data) external payable returns (address);
    function handleSend(address sender, bytes memory data)
        external
        payable
        returns (uint256[] memory, bytes memory, uint256);
    function handleOverwrite(address sender, bytes memory data)
        external
        payable
        returns (uint256[] memory, bytes memory, uint256);
    function handleRemove(address sender, bytes memory data) external payable returns (uint256[] memory);

    //////////////////////////////
    // READ
    //////////////////////////////    

    function contractURI() external view returns (string memory);
}
