// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {TransferUtils} from "../TransferUtils.sol";

/**
 * @title FeeManager
 */
contract FeeManager {
    address public immutable feeRecipient;
    uint256 public immutable fee;

    error Fee_Transfer_Failed();
    error Cannot_Set_Recipient_To_Zero_Address();
    error Incorrect_Msg_Value();

    constructor(address _feeRecipient, uint256 _fee) {
        feeRecipient = _feeRecipient;
        fee = _fee;
        if (_feeRecipient == address(0)) {
            revert Cannot_Set_Recipient_To_Zero_Address();
        }
    }

    function getFees(uint256 numStorageSlots) external view returns (uint256) {
        return fee * numStorageSlots;
    }

    // NOTE: formatting of last if statement is very weird
    function _handleFees(uint256 numStorageSlots) internal {
        uint256 totalFee = fee * numStorageSlots;
        if (msg.value != totalFee) revert Incorrect_Msg_Value();
        if (!TransferUtils.safeSendETH(feeRecipient, totalFee, TransferUtils.FUNDS_SEND_LOW_GAS_LIMIT)) {
            revert Fee_Transfer_Failed();
        }
    }
}
