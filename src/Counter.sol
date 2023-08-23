// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Counter {
    uint256 public counter;
    address router;
    uint256 constant dataSceheme = 2;
    bytes32 public merkleRoot;

    struct Listing {
        uint128 chainId;
        uint128 tokenId;
        address listingAddress;
        bool hasTokenId;
    }

    event ListingTransmitted(
        address sender,
        uint256 id,
        Listing listing
    );

    error Sender_Not_Router();

    function transmitDat2(address sender, bytes memory data) external returns (uint256[] memory, bytes[] memory, uint256) {
        if (msg.sender != router) revert Sender_Not_Router();
        (bytes32[] memory proof, Listing[] memory listings) = abi.decode(data, (Bytes32[], Listing[]));
        uint256[] memory ids = new uint256[](listings.length);
        bytes[] memory encodedData = new bytes[](listings.length);
        if (!merkleProofCheck(root, proof, sender)) revert No_Access();
        for (uint256 i; i < listings.length; ++i) {
            ids[i] = counter;
            encodedData[i] = abi.encode(listings[0]);
            ++counter;
        }
        return (ids, encodedData, dataScheme);
    }    

    function transmitData(address sender, bytes memory data) external returns (uint256[] memory, address[] memory) {
        // if (msg.sender != router) revert Sender_Not_Router();
        (Listing[] memory listings) = abi.decode(data, (Listing[]));
        uint256[] memory ids = new uint256[](listings.length);
        for (uint256 i; i < listings.length; ++i) {
            ids[i] = counter;
            emit ListingTransmitted({
                sender: sender,
                id: counter,
                listing: listings[i]
            });            
            ++counter;
        }
        return (ids, _generateArrayOfZeroAddrs(listings.length));
    }

    function _generateArrayOfZeroAddrs(uint256 quantity) internal pure returns (address[] memory) {
        address[] memory arrayOfZeroAddrs = new address[](quantity);
        for (uint256 i; i < quantity; ++i) {
            arrayOfZeroAddrs[i] = address(0);
        }
        return arrayOfZeroAddrs;
    } 
}

/*
    table of tokenless press contracts for curation

    pretendIndexer() {

        address constant tokenlessCurationContract = 0x222
        address constant normalContracts = 0x33

        *** new press emitted emitted ***

        if (factoryImpl == 0x222) {
            allTokenlessPressContracts.push(newPress)
        } else if (factoryImpl = 0x333) {
            allNormalContractsl.push(newPress)
        )



        *** new curation data emitted ***

        if (pressTable[press].factoryImpl = { 0x222, 0x333, 0x444 } {
            get event log from router
            TokenDataStored(msg.sender, press, tokenIds, pointers);

            track down data tranmission events from tokenless press
            for (length tokenIds) {

                lookup event from Press that have a matching Id
                get the listing data from it
                store that in our listing table
            }
        }
    }
*/