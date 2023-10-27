<!-- A breakdown of smart contract sytem design

- Three core contracts
    - IdRegistry.sol
    - DelegateRegistry.sol
    - NodeRegistry.sol
- Node

    // This function allows for the sending of generic data/instructions to target nodes
    //      All operations are conducted offchain according to system specific rulesets
    //      allowing the submission of data in generic formats
    //
    // EX: data = abi.encode(uint256 id, uint256 nodeId, uint256 nodeId, address[] initialAdmins)
    // EX2: data = abi.encode(uint256 id, uint256 nodeId, Publication publication)
    //
    // How do ppl know what schema to use for a given message?
    //      
    //


/*

    How do we set the nodeRegistry up for ourselves
        - how do we know what nodeIds correspond to what type of data?

    1. Deploy NodeRegistry
    2. Register `PublicationNode` which happens to be nodeId #1
        - we know that messages sent to this node must follow the
            Publication schema we have set.
        - well also only ever call messageNode from a specific signer address 
            that we correspond with node #1
    3. Start Registering ChannelIds
        - we know that channelIds begin after nodeId #1
        - we will only ever listen to Messages emitted 
        - signer X = used for Publications
        - signer Y = used for Channels


*/ -->