// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {IdRegistry} from "../core/IdRegistry.sol";

/**
 * @title RiverIdValidator
 * @author Lifeworld
 */
contract RiverIdValidator  {

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////   

    /// @dev Revert when the Validate caller is not riverNetSigner
    error Only_RiverSigner();    

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////    

    /**
     * @dev Emit an event when validate is called
     *
     *      NOTE: add description
     *
     * @param id            Id being validated
     */
    event Validate(uint256 id);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////        

    address public immutable riverNetSigner;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////      

    constructor(address _riverNetSigner) {
        riverNetSigner = _riverNetSigner;
    }

    //////////////////////////////////////////////////
    // ID VALIDATION
    //////////////////////////////////////////////////    

    // Note: this has bery basic logic because we know we will be deprecating
    // this Validator in the near term
    function validateTrusted(uint256 id) external {
        // Check if sender is riverNetSigner
        if (msg.sender != riverNetSigner) revert Only_RiverSigner();
        // Emit validation event for target id
        emit Validate(id);      
    }
}