// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IFactory} from "../../../../core/factory/interfaces/IFactory.sol";
import {PressProxy} from "../../../../core/press/proxy/PressProxy.sol";
import {PressTransmitterListings} from "../press/PressTransmitterListings.sol";

/**
 * @title FactoryTransmitterListings
 */
contract FactoryTransmitterListings is IFactory {
    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    

    struct Inputs {
        string pressName;
        bytes pressData;
        address initialOwner;
        address logic;
        bytes logicInit;
        address renderer;
        bytes rendererInit;
    }    
    
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    address public router;
    address public pressImpl;

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error when msg.sender is not the router
    error Sender_Not_Router();


    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////

    constructor(address _router, address _pressImpl) {
        router = _router;
        pressImpl = _pressImpl;
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////

    // dont think this needs a reentrancy guard, since a callback to the Factory mid createPress
    //      execution cant do anyting malicious? only function is to create another new press?
    function createPress(address sender, bytes memory init) external returns (address, address) {
        if (msg.sender != router) revert Sender_Not_Router();
        /* 
            Could put factory logic check here for sender access
            Could also take out sender from being an input, but seems nice to have
        */
        // Decode init data
        (Inputs memory inputs) = abi.decode(init, (Inputs));
        // Configure ownership details in proxy constructor
        PressProxy newPress = new PressProxy(pressImpl, "");
        // Initialize PressProxy
        address newPressDataPointer = PressTransmitterListings(payable(address(newPress))).initialize({
            pressName: inputs.pressName,
            pressData: inputs.pressData,
            initialOwner: inputs.initialOwner,
            routerAddr: router, // input comes from local storage not decode
            logic: inputs.logic,
            logicInit: inputs.logicInit,
            renderer: inputs.renderer,
            rendererInit: inputs.rendererInit
        });
        return (address(newPress), newPressDataPointer);
    }
}
