A breakdown of smart contract sytem design

- Three core contracts
    - idRegistry.sol
    - channelRegistry.sol
    - mediaRegistry.sol
- Ids
    - All activity on river is attributed to rids (River Ids)
    - Rids are created through the idRegistry. They are numerical based, and for our use case are roughly unlimited
    - Rids are associated with a given owner address, and an address can only be the onwer of one id at a time
    - Upon registration, users can also assign a backup address that can be used to recover an rid in case of
        a vulnberability in their primary owner address
    - The current registration flow requires the txn to be initiated by the desired owner of the rid,
        but a function will be introduced to allow a trusted actor to register and assign rids on behalf of users,
        while still requiring a signature for initialization
- Channels
    - Channels are the core information primative on River
    - ChannelIds serve as a construct to organize data around, with rids serving as the mechanism
        through which provenance can be attributed to individual accounts
    - New channels are created by calling `createNewChannel()` and the emission of `NewChannel` events, which include the following:
        - txn caller (address)
        - newly created channelId (uint256)
        - channelId initialization data (bytes)
            - channelId initialization data is an encoded blob that contains the following contents
                - rid (uint256) to receieve provenance
                - accessSchema (uint256) to setup for channelId related actions
                - accesScehemaData (bytes) to setup for channelId related actions
                    - schema specific data to decode and store in channel access schema store
                        - ex: abi.encode(address[] admins, bytes32 merkleRoot)
                - uri (string) ipfs pointer to channelUri json that contains the following:
                    - name (string)
                    - description (string)
                    - cover image uri (string), which itself should be a pointer to decentralized file storage provider
    - Data is passed through channels by calling `submitChannelAction()` and the emission of `ChannelAction` events, which are encoded blobs of data with the follwing contents
        - rid (uint256) to receive provenance
        - channelId (uint256) to target
        - actionId (uint256) to target
        - data (bytes) to process
            - ex: abi.encode(Pointers[]);
    - Their are no contract-level blocks on the creation of new channels OR the emission of channel actions. 
        All access control + indexing logic occurs off-chain as designated in the Delta implementation
- Media
    - The media registry is structured similarly to the id + channel registry but also inherits
        an ERC1155 implementation to enable tokenization