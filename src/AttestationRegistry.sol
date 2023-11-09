// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title AttestationRegistry
 * @author Lifeworld
 */
contract AttestationRegistry {

    // TODO:
    // Consider adding "attestFor" event. which can be called by anyone
    // and must pass through a valid signature check for a given "for" address/id

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////       

    event Attest(address indexed from, address indexed to, bool indexed status, uint256 timestamp); 

    //////////////////////////////////////////////////
    // ATTEST
    //////////////////////////////////////////////////    

    /*
        HOW DOES INCLUSION WORK?

        ** Indexer must be synced with most up to date IdRegistry address as specified in IMP

        1. lookup id for msg.sender.
            - if (idRegistry.idOwnedBy(msg.sender == 0)) REVERT()
        2. look up existing attestations for id in data store. 
            - if attestation exists for id, and inputted status is true, REVERT()
        3. look up most recent Register/Transfer/Recovery timestamp for id
            - if event reg/trsnf/recov timestamp > inputted timestamp, REVERT()
        4. check if inputted timestamp is within 24 hours of the Attest event emission
            - if Attest timestamp + 24 hours < inputted timestamp, REVERT() 
        5. update attest data store for given id, marking "to" address as the inputted status boolean 

    */
    
    function attest(address to, bool status, uint256 timestamp) external {
        emit Attest(msg.sender, to, status, timestamp);
    }
}