// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

abstract contract Types {
    
    //////////////////////////////////////////////////
    // GENERIC
    //////////////////////////////////////////////////

    function exportType_000_Message() external pure returns (uint256 userId, uint256 msgType, bytes memory msgBody) {
        return (userId, msgType, msgBody);
    }

    //////////////////////////////////////////////////
    // ACCESS CONTROL
    //////////////////////////////////////////////////

    function exportType_101_Access_AdminWithMembers() external pure returns (uint256[] memory admins, uint256[] memory members) {
        return (admins, members);
    }

    //////////////////////////////////////////////////
    // PUBLICATION
    //////////////////////////////////////////////////    

    function exportType_201_Publication_SetUri() external pure returns (string memory uri) {
        return (uri);
    }    

    //////////////////////////////////////////////////
    // CHANNEL
    //////////////////////////////////////////////////   

    function exportType_301_Channel_SetUri() external pure returns (string memory uri) {
        return (uri);
    }        

    function exportType_302_Channel_AddItem() external pure returns (uint256 chainId, uint256 id, address pointer, bool hasId) {
        return (chainId, id, pointer, hasId);
    }          

    function exportType_303_Channel_RemoveItem() external pure returns (uint256 channelIndex) {
        return (channelIndex);
    }         
}
