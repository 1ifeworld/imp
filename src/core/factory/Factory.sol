// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IFactory} from "./interfaces/IFactory.sol";
import {PressTokenless} from "../press/implementations/tokenless/PressTokenless.sol";
import {PressProxy} from "../press/proxy/PressProxy.sol";

/**
 * @title Factory
 */
contract Factory is IFactory {
    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    

    struct Inputs {
        string pressName;
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
    function createPress(address sender, bytes memory init) external returns (address) {
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
        PressTokenless(payable(address(newPress))).initialize({
            pressName: inputs.pressName,
            initialOwner: inputs.initialOwner,
            routerAddr: router, // input comes from local storage not decode
            logic: inputs.logic,
            logicInit: inputs.logicInit,
            renderer: inputs.renderer,
            rendererInit: inputs.rendererInit
        });
        return address(newPress);
    }
}
