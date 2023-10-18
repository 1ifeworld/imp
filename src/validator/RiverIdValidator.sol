// SPDX-License-Identifier: AGPL 3.0
pragma solidity 0.8.21;

import {IdRegistry} from "../core/IdRegistry.sol";

/**
 * @title RiverIdValidator
 * @author Lifeworld.
 */
contract RiverIdValidator  {

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////   

    /// @dev Revert when the Validate caller is not riverNetsigner
    error Untrusted_Validator();    
    /// @dev Revert when designated start time is before current block.timestamp
    error Invalid_Timestamp();
    /// @dev Revert when designated duration is shorter than one month
    error Invalid_Duration();

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

    IdRegistry public immutable idRegistry;
    address public immutable riverNetSigner;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////      

    constructor(address _idRegistry, address _riverNetSigner) {
        idRegistry = IdRegistry(_idRegistry);
        riverNetSigner = _riverNetSigner;
    }

    //////////////////////////////////////////////////
    // ID VALIDATION
    //////////////////////////////////////////////////    

    // Note: this has bery basic logic because we know we will be deprecating
    // this Validator in the near term
    function validateTrusted(uint256 id) external {
        // Check if sender is riverNetSigner
        if (msg.sender != riverNetSigner) revert Untrusted_Validator();
        // Emit validation event for target id
        emit Validate(id);      
    }
}