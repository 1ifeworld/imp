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

    /// @notice Initializes a PressProxy
    function initialize(        
        string memory pressName, 
        address initialOwner,
        address routerAddr,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit
    ) external;

    // function updatePressData(address press, bytes memory data) external payable returns (address);
    // function storeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory);
    // function overwriteTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory);
    // function removeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory);
    function transmitData(address sender, bytes memory data) external payable returns (uint256[] memory, bytes memory, uint256);
}