// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/* woah */

interface IRouter {
    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    event FactoryRegistered(address sender, address[] factories, bool[] statuses);
    event PressRegistered(address sender, address factory, address newPress, address newPressData);
    event PressDataUpdated(address sender, address press, address pointer);
    event DataSent(address sender, address press, uint256[] ids, bytes response, uint256 schema);
    event DataOverwritten(address sender, address press, uint256[] ids, bytes response, uint256 schema);
    event DataRemoved(address sender, address press, uint256[] ids);

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error when trying to use a factory that is not registered
    error Factory_Not_Registered();
    /// @notice Error when trying to target a press that is not registered
    error Press_Not_Registered();
    /// @notice Error when inputting arrays with non matching length
    error Input_Length_Mismatch();
}