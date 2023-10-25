// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {ERC1155, ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
// import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
// import "sstore2/SSTORE2.sol";
// import {ISaleModule} from "./interfaces/ISaleModule.sol";
// import {FundsReceiver} from "../utils/FundsReceiver.sol";
// import {TransferUtils} from "../utils/TransferUtils.sol";

// /**
//  * @title MediaRegistry
//  */
// contract MediaRegistry is 
//     ERC1155, 
//     ReentrancyGuard,     
//     FundsReceiver 
// {

//     event Collected(address sender, address recipient, uint256 tokenId, uint256 quantity, uint256 price);

//     error Not_Trusted_Operator();
//     error Admin_Restricted_Access();
//     error Sale_Module_Not_Registered();
//     error No_Collect_Access();
//     error Incorrect_Msg_Value();
//     error ETHTransferFailed(address recipient, uint256 amount);

//     address internal immutable _trustedOperator;
//     uint256 public idCounter;
//     mapping(uint256 => address) public idToAdmin;
//     mapping(uint256 => address) public idToUri;
//     mapping(uint256 => address) public idToSaleModule;

//     constructor(address trustedOperator) {
//         _trustedOperator = trustedOperator;
//     }

//     // consider adding back in ability to designate different recipietnt address
//     // than msg.sender
//     function createToken(address admin, string memory mediaUri) external returns (uint256 id) {
//         // Increment and assign new tokenId
//         id = ++idCounter;
//         // Assign admin
//         idToAdmin[id] = admin;
//         // Assign uri
//         idToUri[id] = SSTORE2.write(bytes(mediaUri));
//         // Mint new token
//         _mint(msg.sender, id, 1, new bytes(0));
//         // Emit for indexing
//         emit URI(mediaUri, id);
//     }

//     function createTokens(address admin, string[] memory mediaUris) external returns (uint256[] memory ids) {
//         // Cache token quantity
//         uint256 quantity = mediaUris.length;
//         // Initialize ids array for return
//         ids = new uint256[](quantity);
//         // Begin for loop
//         for (uint256 i; i < quantity; ++i) {
//             // Increment and assign new tokenId
//             ids[i] = ++idCounter;
//             // Assign admin
//             idToAdmin[ids[i]] = admin;
//             // Assign uri
//             idToUri[ids[i]] = SSTORE2.write(bytes(mediaUris[i]));
//             // Emit for metadata indexing
//             emit URI(mediaUris[i], ids[i]);
//         }
//         // Mint new tokens
//         _batchMint(msg.sender, ids, _singleton(quantity), new bytes(0));
//     }

//     // consider adding back in ability to designate different recipietny address
//     // than attribution address
//     function trustedCreateToken(address attribution, address admin, string memory mediaUri)
//         external
//         returns (uint256 id)
//     {
//         // Confirm transaction coming from trusted operator
//         if (msg.sender != _trustedOperator) revert Not_Trusted_Operator();
//         // Increment and assign new tokenId
//         id = ++idCounter;
//         // Assign admin
//         idToAdmin[id] = admin;
//         // Assign uri
//         idToUri[id] = SSTORE2.write(bytes(mediaUri));
//         // Mint new token
//         _trustedMint(attribution, id, 1, new bytes(0));
//         // Emit for indexing
//         emit URI(mediaUri, id);
//     }

//     function trustedCreateTokens(address attribution, address admin, string[] memory mediaUris)
//         external
//         returns (uint256[] memory ids)
//     {
//         // Confirm transaction coming from trusted operator
//         if (msg.sender != _trustedOperator) revert Not_Trusted_Operator();
//         // Cache token quantity
//         uint256 quantity = mediaUris.length;
//         // Initialize ids array for return
//         ids = new uint256[](quantity);
//         // Begin for loop
//         for (uint256 i; i < quantity; ++i) {
//             // Increment and assign new tokenId
//             ids[i] = ++idCounter;
//             // Assign admin
//             idToAdmin[ids[i]] = admin;
//             // Assign uri
//             idToUri[ids[i]] = SSTORE2.write(bytes(mediaUris[i]));
//             // Emit for metadata indexing
//             emit URI(mediaUris[i], ids[i]);
//         }
//         // Mint new tokens
//         _trustedBatchMint(attribution, ids, _singleton(quantity), new bytes(0));
//     }

//     function createSale(uint256 tokenId, address saleModule, bytes memory saleModuleInit) external {
//         // Cache msg.sender        
//         address sender = msg.sender;         
//         // Check if sender has admin access
//         if (sender != idToAdmin[tokenId]) revert Admin_Restricted_Access();
//         // Set + initialize sale module for tokenId
//         idToSaleModule[tokenId] = saleModule;
//         ISaleModule(saleModule).setupSale(sender, tokenId, saleModuleInit);
//     }

//     // consider adding the ability to add a specific module target, which would then require us
//     // to update the saleModule mapping to include an additional bool flag, which would enable
//     // multiple valid collect strategies operating at once for a given token
//     function collect(address recipient, uint256 tokenId, uint256 quantity) external payable nonReentrant {
//         // Check if sales module has been registered for this token
//         if (idToSaleModule[tokenId] == address(0)) revert Sale_Module_Not_Registered();
//         // Cache msg.sender        
//         address sender = msg.sender; 
//         // Get collect rules for given sales module
//         // TODO: make sure not having the recipietny in the requestCollect call isnt necessary
//         //      could replace everything except tokenId (or at least quantity) with a bytes value
//         //      that could make it so the sales logic can process additional commands as well (ex: redemption flows)
//         (bool access, uint256 price, address fundsRecipient) = ISaleModule(idToSaleModule[tokenId]).requestCollect(sender, tokenId, quantity);   
//         if (!access) revert No_Collect_Access();             
//         if (msg.value != price) revert Incorrect_Msg_Value();
//         // Process mint
//         _mint(recipient, tokenId, quantity, new bytes(0));        
//         // Transfer funds to specified tokenId recipient, revert if transfer failed
//         if (!TransferUtils.safeSendETH(
//             fundsRecipient,
//             price, 
//             TransferUtils.FUNDS_SEND_NORMAL_GAS_LIMIT
//         )) {
//             revert ETHTransferFailed(fundsRecipient, price);
//         }                              
//         // Emit Collected event
//         emit Collected(sender, recipient, tokenId, quantity, price);
//         /*
//             NOTE: for later
//             potentially add a check here to refund eth sent for collect if hasnt
//             been fully sent yet. this would protect from ppl sending funds to 
//             collect a tokenId whose recipient address is address(0)
//         */
               
//     }

//     ////////////////////////////////////////////////////////////
//     // READ FUNCTIONS
//     ////////////////////////////////////////////////////////////

//     function uri(uint256 id) public view override returns (string memory) {
//         return string(SSTORE2.read(idToUri[id]));
//     }

//     ////////////////////////////////////////////////////////////
//     // HELPERS
//     ////////////////////////////////////////////////////////////

//     function _singleton(uint256 length) internal pure returns (uint256[] memory array) {
//         array = new uint256[](length);
//         for (uint256 i; i < length; ++i) {
//             array[i] = 1;
//         }
//         return array;
//     }
// }