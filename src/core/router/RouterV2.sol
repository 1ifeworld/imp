// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";

/**
 * @title RouterV2
 * @author Lifeworld
 */
contract RouterV2 is ReentrancyGuard, Ownable, FundsReceiver {
    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    /*
        NOTE: could potentially add the include msg.sender flag into call Input
        to simplify DX + save gas on the flag enabled call
    */

    struct CallInputs {
        address target;
        bytes4 selector;
        bytes data;
    }


    // slot 1: 7 + 20 + 1 + 4 = 32
    // slot 2: unstructured bytes = ???
    struct CallInputsExtended {
        uint56 value;
        address target;
        uint8 senderFlag;
        bytes4 selector;
        bytes data;
    }

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    uint256 public constant ROUTER_VERSION = 2;

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
    error Call_Failed_Extended(CallInputsExtended inputs);

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    //////////////////////////////
    // TARGET CALLS
    //////////////////////////////

    function callTarget(CallInputs calldata callInputs) external payable nonReentrant {
        (bool success,) = callInputs.target.call{value: msg.value}(
            abi.encodePacked(callInputs.selector, abi.encode(msg.sender, callInputs.data))
        );
        if (!success) revert Call_Failed(callInputs);
    }

    function callTargetMulti(CallInputsExtended[] calldata callInputs)
        external
        payable
        nonReentrant
    {
        address sender = msg.sender;
        for (uint256 i; i < callInputs.length; ++i) {
            (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                abi.encodePacked(callInputs[i].selector, abi.encode(sender, callInputs[i].data))
            );
            if (!success) revert Call_Failed_Extended(callInputs[i]);
        }
    }

    /* 
    * 
    * NO MSG.SENDER VARIANTS 
    *
    */

    function callTargetWithoutSender(CallInputs calldata callInputs) external payable nonReentrant {
        (bool success,) =
            callInputs.target.call{value: msg.value}(abi.encodePacked(callInputs.selector, callInputs.data));
        if (!success) revert Call_Failed(callInputs);
    }

    function callTargetMultiWithoutSender(CallInputsExtended[] calldata callInputs)
        external
        payable
        nonReentrant
    {        
        for (uint256 i; i < callInputs.length; ++i) {
            (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                abi.encodePacked(callInputs[i].selector, callInputs[i].data)
            );
            if (!success) revert Call_Failed_Extended(callInputs[i]);
        }     
    }

    /* 
    * 
    * "EITHER-OR" MSG.SENDEER VARIANT
    *
    */    

    function callTargetMultiWithOrWithoutSender(CallInputsExtended[] calldata callInputs)
        external
        payable
        nonReentrant
    {
        address sender = msg.sender;
        for (uint256 i; i < callInputs.length; ++i) {
            if (callInputs[i].senderFlag == 1) {
                // Encode msg.sender and pass into function call data
                (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                    abi.encodePacked(callInputs[i].selector, abi.encode(sender, callInputs[i].data))
                );
                if (!success) revert Call_Failed_Extended(callInputs[i]);
            } else {
                // Do not pass msg.sender into function call
                (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                    abi.encodePacked(callInputs[i].selector, callInputs[i].data)
                );
                if (!success) revert Call_Failed_Extended(callInputs[i]);
            }
        }
    }
}
