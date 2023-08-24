// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "sstore2/SSTORE2.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IPress} from "../../interfaces/IPress.sol";
import {IPressTokenlessTypesV1} from "./types/IPressTokenlessTypesV1.sol";
import {IPressTypesV1} from "../../types/IPressTypesV1.sol";
import {PressStorageV1} from "../../storage/PressStorageV1.sol";
import {ILogic} from "../../logic/ILogic.sol";
import {IRenderer} from "../../renderer/IRenderer.sol";
import {FeeManager} from "../../fees/FeeManager.sol";
import {TransferUtils} from "../../../../utils/TransferUtils.sol";
import {OwnableUpgradeable} from "../../../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../../../utils/Version.sol";
import {FundsReceiver} from "../../../../utils/FundsReceiver.sol";

/**
 * @title PressTokenless
 */
contract PressTokenless is
    IPressTokenlessTypesV1,
    IPressTypesV1,
    IPress,
    PressStorageV1,
    FeeManager,
    Version(1),
    FundsReceiver,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{

    ////////////////////////////////////////////////////////////
    // STORAGE 
    ////////////////////////////////////////////////////////////  

    uint256 constant DATA_SCHEMA = 2;
    mapping(uint256 => address) public idOrigin;

    ////////////////////////////////////////////////////////////
    // ERRORS 
    ////////////////////////////////////////////////////////////      

    error No_Access();
    error Overwrite_Not_Supported();

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR 
    ////////////////////////////////////////////////////////////    

    constructor(address _feeRecipient, uint256 _fee) FeeManager(_feeRecipient, _fee) {}

    ////////////////////////////////////////////////////////////
    // INITIALIZER 
    ////////////////////////////////////////////////////////////

    /**
    * @notice Initializes a new, creator-owned proxy of Press.sol
    */
    function initialize(
        string memory pressName, 
        address initialOwner,
        address routerAddr,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit
    ) external nonReentrant initializer {
        // We are not initalizing the OZ 1155 implementation
        // to save contract storage space and runtime
        // since the only thing affected here is the uri.
        // __ERC1155_init("");

        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable 
        __Ownable_init(initialOwner);
        // Setup UUPS
        __UUPSUpgradeable_init();   

        // Set things
        router = routerAddr;
        name = pressName;

        // Set press storage
        ++settings.counter; // this acts as an initialization check since will be 0 before init
        settings.logic = logic;
        settings.renderer = renderer;
        
        // Initialize logic + renderer
        ILogic(logic).initializeWithData(logicInit);
        IRenderer(renderer).initializeWithData(rendererInit);
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////      

    //////////////////////////////
    // EXTERNAL
    //////////////////////////////  

    /* ~~~ Token Data Interactions ~~~ */

    function handleSend(address sender, bytes memory data) external payable returns (uint256[] memory, bytes memory, uint256) {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (bytes32[] memory merkleProof, Listing[] memory listings) = abi.decode(data, (bytes32[], Listing[]));
        // Initialize ids memory array for return
        uint256[] memory ids = new uint256[](listings.length);
        // Request send access from logic contract for given sender, quantity, and merkleProof
        if (!ILogic(settings.logic).getSendAccess(sender, listings.length, merkleProof)) revert No_Access();
        // Store sender + increment id counter for each piece of data
        for (uint256 i; i < listings.length; ++i) {
            ids[i] = settings.counter;
            idOrigin[i] = sender;
            ++settings.counter;
        }
        // Handle system fees for given quantity of data
        _handleFees(listings.length);      
        // Send response back to router for event emission
        return (ids, abi.encode(listings), DATA_SCHEMA);
    }     

    function handleOverwrite(address sender, bytes memory data) external payable returns (uint256[] memory) {
        revert Overwrite_Not_Supported();
    }             

    function handleRemove(address sender, bytes memory data) external payable returns (uint256[] memory) {
        // Confirm transaction coming from router
        if (msg.sender != router) revert Sender_Not_Router();
        // Decode incoming data
        (uint256[] memory ids) = abi.decode(data, (uint256[]));
        // Increment id counter for each piece of data
        for (uint256 i; i < ids.length; ++i) {
            // Request remove access from logic contract for given sender + id
            if (!ILogic(settings.logic).getRemoveAccess(sender, ids[i])) revert No_Access();            
        }    
        // Send response back to router for event emission
        return ids;
    }                 

    /* ~~~ Press Data Interactions ~~~ */          

    function updatePressData(address sender, bytes memory data) external payable returns (address) {        
        if (msg.sender != router) revert Sender_Not_Router();        
        /* 
            Could put logic check here for sender
        */        
        // Hardcoded `1` value since this function only updates 1 storage slot
        _handleFees(1);        
        (bytes memory dataToStore) = abi.decode(data, (bytes));        
        if (dataToStore.length == 0) {
            delete pressData;
            return pressData;
        } else {
            /* 
                Could put fee logic here, for when people are storing data
                Could even check if press data is zero or not 
                Otherwise maybe best to make this function non payable
            */      
            pressData = SSTORE2.write(dataToStore);
            return pressData;
        }
    }        

    //////////////////////////////
    // INTERNAL
    //////////////////////////////               

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////     

    // TODO: add some type of check whether the id exists or not?
    function getIdOrigin(uint256 id) external view returns (address) {
        return idOrigin[id];
    }

    //////////////////////////////
    // INTERNAL
    //////////////////////////////        

    /**
     * @param newImplementation proposed new upgrade implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override {}      
  
    /**
     * @notice Helper function
     */    
    function _generateArrayOfOnes(uint256 quantity) internal pure returns (uint256[] memory) {
        uint256[] memory arrayOfOnes = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            arrayOfOnes[i] = 1;
        }
        return arrayOfOnes;
    } 
}