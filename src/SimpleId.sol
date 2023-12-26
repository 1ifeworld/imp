// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Signatures} from "./abstract/Signatures.sol";
import {Nonces} from "./abstract/Nonces.sol";
import {EIP712} from "./abstract/EIP712.sol";

/**
 * @title SimpleId
 * @author Lifeworld
 */
contract SimpleId is Signatures, Nonces, EIP712 {

    // Errors
    error Has_Id();      

    // Errors
    event Register(address to, uint256 id, address recovery);

    // Constants

    bytes32 public constant REGISTER_TYPEHASH =
        keccak256("Register(address to,address recovery,uint256 nonce,uint256 deadline)");    

    // Storage

    uint256 public idCounter;
    mapping(address owner => uint256 id) public idOf;
    mapping(uint256 id => address custody) public custodyOf;
    mapping(uint256 id => address recovery) public recoveryOf;

    // Constructor
    constructor() EIP712("Lifeworld IdRegistry", "1") {}    
    
    // Register

    function registerFor(
        address to,
        address recovery,
        uint256 deadline,
        bytes calldata sig
    ) external returns (uint256 id) {
        // Revert if signature is invalid
        _verifyRegisterSig({to: to, recovery: recovery, deadline: deadline, sig: sig});
        // check to address doesnt own id
        if (idOf[to] != 0) revert Has_Id();
        // increment id counter
        id = ++idCounter;
        // assign id to custody address
        idOf[to] = id;
        // assign custody address to id
        custodyOf[id] = to;
        // assign id recovery to address
        recoveryOf[id] = recovery;
        // emit event
        emit Register(to, id, recovery);
    }

    function _verifyRegisterSig(address to, address recovery, uint256 deadline, bytes memory sig) internal {
        _verifySig(
            _hashTypedDataV4(keccak256(abi.encode(REGISTER_TYPEHASH, to, recovery, _useNonce(to), deadline))),
            to,
            deadline,
            sig
        );
    }    

    // Transfer

    // Backup

}
