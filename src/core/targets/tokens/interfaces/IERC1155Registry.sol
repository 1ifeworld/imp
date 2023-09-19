// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC1155Registry {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    // event UriUpdated(address sender, uint256 channelId, string uri);
    event Collected(address sender, address recipient, uint256 tokenId, uint256 quantity, uint256 price);
    

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    error Sender_Not_Router();
    error No_Sales_Module_Registered();
    error No_Collect_Access();
    error ETHTransferFailed(address recipient, uint256 amount);

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////
    function createTokens(address sender, bytes memory data) external payable;

    // /**
    //  * @notice Creates a new channel
    //  */
    // function newChannel(address sender, bytes memory data) external;
}
