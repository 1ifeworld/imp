// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title DelegateRegistry
 * @author Lifeworld
 */
contract DelegateRegistry {

    // TODO:
    // Consider adding "delegateFor" event. which can be called by anyone
    // and must pass through a valid signature check for a given "for" address/id

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////       

    event Delegate(address indexed from, address indexed to, bool indexed status, uint256 timestamp); 

    //////////////////////////////////////////////////
    // ATTEST
    //////////////////////////////////////////////////    

    /*
        HOW DOES INCLUSION WORK?

        ** Indexer must be synced with most up to date IdRegistry address as specified in IMP

        1. lookup id for msg.sender.
            - if (idRegistry.idOwnedBy(msg.sender == 0)) REVERT()
        2. look up existing delegations for id in data store. 
            - if inputted status boolean is already present for id, REVERT()
        3. look up most recent Register/Transfer/Recovery timestamp for id
            - if event reg/trsnf/recov timestamp > inputted timestamp, REVERT()
        4. check if inputted timestamp is within 24 hours of the Delegate event emission
            - if Delegate timestamp + 24 hours < inputted timestamp, REVERT() 
        5. update delegate data store for given id, marking "to" address as the inputted status boolean 

    */
    
    function delegate(address to, bool status, uint256 timestamp) external {
        emit Delegate(msg.sender, to, status, timestamp);
    }
}