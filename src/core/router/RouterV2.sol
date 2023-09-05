// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @title RouterV2
 * @author Max Bochman
 */
contract RouterV2 is ReentrancyGuard {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    struct CallInputs {
        address target;
        bytes4 selector;
        bytes data;
    }

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////    

    mapping(address => bool) public targetRegistry;
    mapping(address => mapping(bytes4 => bool)) public selectorRegistry;
    uint256 targetRegistryCounter;
    mapping(address => uint256) selectorRegistryCounter;

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    error Target_Already_Registered();
    error Cannot_Register_ZeroAddress();
    error Selector_Already_Registered();
    error Input_Length_Mismatch();
    error Unregistered_Target();
    error Unregistered_Selector();
    error Call_Failed(CallInputs inputs);

    //////////////////////////////////////////////////
    // TARGET + SELECTOR REGISTRATION
    //////////////////////////////////////////////////    

    // TODO: Add access control
    function registerTarget(address target, bytes4[] memory selectors) external nonReentrant {
        if (targetRegistry[target]) revert Target_Already_Registered();
        if (target == address(0)) revert Cannot_Register_ZeroAddress();
        targetRegistry[target] = true;
        ++targetRegistryCounter;
        for (uint256 i; i < selectors.length; i++) {
            selectorRegistry[target][selectors[i]] = true;
        }
        selectorRegistryCounter[target] += selectors.length;
    }

    // TODO: Add access control
    function addSelectors(address target, bytes4[] memory selectors) external nonReentrant {
        if (!targetRegistry[target]) revert Unregistered_Target();
        for (uint256 i; i < selectors.length; i++) {
            if (selectorRegistry[target][selectors[i]]) revert Selector_Already_Registered();
            selectorRegistry[target][selectors[i]] = true;
        }
        selectorRegistryCounter[target] += selectors.length;
    }

    //////////////////////////////////////////////////
    // TARGET CALLS
    //////////////////////////////////////////////////        

    function callTarget(CallInputs calldata callInputs) external payable nonReentrant {
        if (!targetRegistry[callInputs.target]) revert Unregistered_Target();
        if (!selectorRegistry[callInputs.target][callInputs.selector]) revert Unregistered_Selector();
        (bool success,) = callInputs.target.call{value: msg.value}(
            abi.encodePacked(callInputs.selector, abi.encode(msg.sender, callInputs.data))
        );
        if (!success) revert Call_Failed(callInputs);
    }

    function callTargetMulti(CallInputs[] calldata callInputs, uint256[] calldata callValues)
        external
        payable
        nonReentrant
    {
        // Cache msg.sender
        address sender = msg.sender;
        if (callInputs.length != callValues.length) revert Input_Length_Mismatch();
        for (uint256 i; i < callInputs.length; ++i) {
            if (!targetRegistry[callInputs[i].target]) revert Unregistered_Target();
            if (!selectorRegistry[callInputs[i].target][callInputs[i].selector]) revert Unregistered_Selector();
            (bool success,) = callInputs[i].target.call{value: callValues[i]}(
                abi.encodePacked(callInputs[i].selector, abi.encode(sender, callInputs[i].data))
            );
            if (!success) revert Call_Failed(callInputs[i]);
        }
    }

    /* 
    * 
    * NO MSG.SENDER VARIANTS 
    * NOTE: Not sure if we actually care about these or not
    *
    */

    function callTargetWithoutSender(CallInputs calldata callInputs) external payable nonReentrant {
        if (!targetRegistry[callInputs.target]) revert Unregistered_Target();
        if (!selectorRegistry[callInputs.target][callInputs.selector]) revert Unregistered_Selector();
        (bool success, bytes memory result) =
            callInputs.target.call{value: msg.value}(abi.encodePacked(callInputs.selector, callInputs.data));
        require(success, string(result));
    }

    function callTargetMultiWithoutSender(CallInputs[] calldata callInputs, uint256[] calldata callValues)
        external
        payable
        nonReentrant
    {
        if (callInputs.length != callValues.length) revert Input_Length_Mismatch();
        for (uint256 i; i < callInputs.length; ++i) {
            if (!targetRegistry[callInputs[i].target]) revert Unregistered_Target();
            if (!selectorRegistry[callInputs[i].target][callInputs[i].selector]) revert Unregistered_Selector();
            (bool success,) = callInputs[i].target.call{value: callValues[i]}(
                abi.encodePacked(callInputs[i].selector, callInputs[i].data)
            );
            if (!success) revert Call_Failed(callInputs[i]);
        }
    }    
}
