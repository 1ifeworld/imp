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
     * @param start         Starting timestamp from which id is valid
     * @param duration      Period of time that id will remain valid
     */
    event Validate(uint256 id, uint256 start, uint256 duration);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////        

    uint256 public constant secondsPerMonth = 2678400;
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

    function validateTrusted(uint256 id, uint256 start, uint256 duration) external {
        // Check if sender is riverNetSigner
        if (msg.sender != riverNetSigner) revert Untrusted_Validator();
        // Check if from timestamp is before current timestamp
        if (start < block.timestamp) revert Invalid_Timestamp();
        if (duration < secondsPerMonth) revert Invalid_Duration();
        // Emit validation event for target id
        emit Validate(id, start, duration);      
    }
}