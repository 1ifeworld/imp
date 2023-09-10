// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/**
 * @title Router
 * @author Lifeworld
 */
contract Router is ReentrancyGuard, Ownable {
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

    uint256 public constant ROUTER_VERSION = 1;
    mapping(address => bool) public targetRegistry;
    // Selectors must always be associated with a specific target
    mapping(address => mapping(bytes4 => bool)) public selectorRegistry;
    uint256 targetCounter;
    mapping(address => uint256) selectorCounter;

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    event TargetRegistered(address sender, address target, bytes4[] selectors);

    event SelectorsAdded(address sender, address target, bytes4[] selectors);

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    error Target_Already_Registered();
    error Selector_Already_Registered();
    error Cannot_Register_ZeroAddress();
    error Input_Length_Mismatch();
    error Unregistered_Target();
    error Unregistered_Selector();
    error Call_Failed(CallInputs inputs);

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    //////////////////////////////
    // TARGET REGISTRATION
    //////////////////////////////

    function registerTarget(address target, bytes4[] memory selectors) external onlyOwner nonReentrant {
        // Registration validity checks
        if (targetRegistry[target]) revert Target_Already_Registered();
        if (target == address(0)) revert Cannot_Register_ZeroAddress();
        // Registration assignment
        targetRegistry[target] = true;
        for (uint256 i; i < selectors.length; i++) {
            selectorRegistry[target][selectors[i]] = true;
        }
        // Update target + selector counters
        ++targetCounter;
        selectorCounter[target] += selectors.length;
        // Emit data for indexing
        emit TargetRegistered(msg.sender, target, selectors);
    }

    function addSelectors(address target, bytes4[] memory selectors) external onlyOwner nonReentrant {
        // Target validity checks
        if (!targetRegistry[target]) revert Unregistered_Target();
        // Selector validity check + assignment
        for (uint256 i; i < selectors.length; i++) {
            if (selectorRegistry[target][selectors[i]]) revert Selector_Already_Registered();
            selectorRegistry[target][selectors[i]] = true;
        }
        // Update selector counter
        selectorCounter[target] += selectors.length;
        // Emit data for indexing
        emit SelectorsAdded(msg.sender, target, selectors);
    }

    //////////////////////////////
    // TARGET CALLS
    //////////////////////////////

    function callTarget(CallInputs calldata callInputs) external payable nonReentrant {
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
        address sender = msg.sender;
        if (callInputs.length != callValues.length) revert Input_Length_Mismatch();
        for (uint256 i; i < callInputs.length; ++i) {
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
        if (!selectorRegistry[callInputs.target][callInputs.selector]) revert Unregistered_Selector();
        (bool success,) =
            callInputs.target.call{value: msg.value}(abi.encodePacked(callInputs.selector, callInputs.data));
        if (!success) revert Call_Failed(callInputs);
    }

    function callTargetMultiWithoutSender(CallInputs[] calldata callInputs, uint256[] calldata callValues)
        external
        payable
        nonReentrant
    {
        if (callInputs.length != callValues.length) revert Input_Length_Mismatch();
        for (uint256 i; i < callInputs.length; ++i) {
            if (!selectorRegistry[callInputs[i].target][callInputs[i].selector]) revert Unregistered_Selector();
            (bool success,) = callInputs[i].target.call{value: callValues[i]}(
                abi.encodePacked(callInputs[i].selector, callInputs[i].data)
            );
            if (!success) revert Call_Failed(callInputs[i]);
        }
    }
}
