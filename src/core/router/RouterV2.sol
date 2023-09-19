// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";

/**
 * @title RouterV2
 * @author Lifeworld
 */
contract RouterV2 is ReentrancyGuard, FundsReceiver {
    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    /* 
        NOTE:
        Struct packing not relevant for function inputs
        because the compilier does not pack these values
        https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#storage-inplace-encoding
    */

    struct SingleTargetInputs {
        address target;
        bytes4 selector;
        bytes data;
    }

    struct MultiTargetInputs {
        address target;
        bytes4 selector;        
        bytes data;
        uint256 value;
    }

    struct MultiTargetInputsExtended {
        address target;
        bytes4 selector;
        bytes data;        
        uint256 value;        
        uint8 senderFlag;
    }

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    error Single_Target_Call_Failed(SingleTargetInputs inputs);
    error Multi_Target_Call_Failed(MultiTargetInputs);
    error Multi_Target_Call_Extended_Failed(MultiTargetInputsExtended);

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /* 
    * 
    * MSG.SENDER VARIANTS 
    *
    */

    function callTarget(SingleTargetInputs calldata callInputs) external payable nonReentrant {
        (bool success,) = callInputs.target.call{value: msg.value}(
            abi.encodePacked(callInputs.selector, abi.encode(msg.sender, callInputs.data))
        );
        if (!success) revert Single_Target_Call_Failed(callInputs);
    }

    function callTargets(MultiTargetInputs[] calldata callInputs) external payable nonReentrant {
        address sender = msg.sender;
        for (uint256 i; i < callInputs.length; ++i) {
            (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                abi.encodePacked(callInputs[i].selector, abi.encode(sender, callInputs[i].data))
            );
            if (!success) revert Multi_Target_Call_Failed(callInputs[i]);
        }
    }

    /* 
    * 
    * NO MSG.SENDER VARIANTS 
    *
    */

    function callTargetWithoutSender(SingleTargetInputs calldata callInputs) external payable nonReentrant {
        (bool success,) =
            callInputs.target.call{value: msg.value}(abi.encodePacked(callInputs.selector, callInputs.data));
        if (!success) revert Single_Target_Call_Failed(callInputs);
    }

    function callTargetsWithoutSender(MultiTargetInputs[] calldata callInputs) external payable nonReentrant {
        for (uint256 i; i < callInputs.length; ++i) {
            (bool success,) = callInputs[i].target.call{value: callInputs[i].value}(
                abi.encodePacked(callInputs[i].selector, callInputs[i].data)
            );
            if (!success) revert Multi_Target_Call_Failed(callInputs[i]);
        }
    }

    /* 
    * 
    * "EITHER-OR" MSG.SENDER VARIANT
    *
    */

    function callTargetsWithSenderFlag(MultiTargetInputsExtended[] calldata callInputs) external payable nonReentrant {
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

    // TODO: Potentially add withdraw function for incorrectly sent funds
    // TODO: Potentially add overspend reimbursements
}
