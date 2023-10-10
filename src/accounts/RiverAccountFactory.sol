// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "openzeppelin-contracts/utils/Create2.sol";
import "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./RiverAccount.sol";

/*
    Things to consider

    - change the createAccount inputs to be bytes memory inputs, uint256 salt
        to allow for more flexible api into future
        -   would need to be paired with update to the RiverAccount impl
            to facilitate decoding of inputs in the `initialize` call
    - allow for accountImpl to be changed over time?
*/

/**
  * Based on ethinfitism `AccountFactory.sol` implementation
  */
contract RiverAccountFactory {
    RiverAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new RiverAccount(_entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address initialAdmin, uint256 salt) public returns (RiverAccount ret) {
        address addr = getAddress(initialAdmin, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return RiverAccount(payable(addr));
        }
        ret = RiverAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(RiverAccount.initialize, (initialAdmin))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address initialAdmin,uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(RiverAccount.initialize, (initialAdmin))
                )
            )));
    }
}