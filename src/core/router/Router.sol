// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {IRouter} from "./interfaces/IRouter.sol";
import {IPress} from "../press/interfaces/IPress.sol";
import {IFactory} from "../factory/interfaces/IFactory.sol";

/**
 * @title Router
 */
contract Router is IRouter, Ownable, ReentrancyGuard {
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    mapping(address => bool) public factoryRegistry;
    mapping(address => bool) public pressRegistry;

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////

    //////////////////////////////
    // ADMIN
    //////////////////////////////

    function registerFactories(address[] memory factories, bool[] memory statuses) external onlyOwner {
        if (factories.length != statuses.length) revert Input_Length_Mismatch();
        for (uint256 i; i < factories.length; ++i) {
            factoryRegistry[factories[i]] = statuses[i];
        }
        emit FactoryRegistered(msg.sender, factories, statuses);
    }

    //////////////////////////////
    // PRESS CREATION
    //////////////////////////////

    function setupPress(address factoryImpl, bytes memory factoryInit)
        external
        payable
        nonReentrant
        returns (address)
    {
        if (!factoryRegistry[factoryImpl]) revert Factory_Not_Registered();
        address press = IFactory(factoryImpl).createPress(msg.sender, factoryInit);
        pressRegistry[press] = true;
        emit PressRegistered(msg.sender, factoryImpl, press);
        return press;
    }

    function setupPressBatch(address[] memory factoryImpls, bytes[] memory factoryInits)
        external
        payable
        nonReentrant
        returns (address[] memory)
    {
        if (factoryImpls.length != factoryInits.length) revert Input_Length_Mismatch();
        address[] memory presses = new address[](factoryImpls.length);
        for (uint256 i; i < factoryImpls.length; ++i) {
            if (!factoryRegistry[factoryImpls[i]]) revert Factory_Not_Registered();
            address press = IFactory(factoryImpls[i]).createPress(msg.sender, factoryInits[i]);
            pressRegistry[press] = true;
            presses[i] = press;
            emit PressRegistered(msg.sender, factoryImpls[i], press);
        }
        return presses;
    }

    //////////////////////////////
    // SINGLE PRESS INTERACTIONS
    //////////////////////////////

    /* ~~~ Press Data Interactions ~~~ */

    function updatePressData(address press, bytes memory data) external payable nonReentrant {
        if (!pressRegistry[press]) revert Press_Not_Registered();
        (address pointer) = IPress(press).updatePressData{value: msg.value}(msg.sender, data);
        emit PressDataUpdated(msg.sender, press, pointer);
    }

    /* ~~~ Cell Data Interactions ~~~ */

    function sendData(address press, bytes memory data) external payable nonReentrant {
        if (!pressRegistry[press]) revert Press_Not_Registered();
        (uint256[] memory ids, bytes memory response, uint256 schema) =
            IPress(press).handleSend{value: msg.value}(msg.sender, data);
        emit DataSent(msg.sender, press, ids, response, schema);
    }

    function overwriteData(address press, bytes memory data) external payable nonReentrant {
        if (!pressRegistry[press]) revert Press_Not_Registered();
        (uint256[] memory ids, bytes memory response, uint256 schema) =
            IPress(press).handleOverwrite{value: msg.value}(msg.sender, data);
        emit DataOverwritten(msg.sender, press, ids, response, schema);
    }

    function removeData(address press, bytes memory data) external payable nonReentrant {
        if (!pressRegistry[press]) revert Press_Not_Registered();
        (uint256[] memory ids) = IPress(press).handleRemove{value: msg.value}(msg.sender, data);
        emit DataRemoved(msg.sender, press, ids);
    }
}
