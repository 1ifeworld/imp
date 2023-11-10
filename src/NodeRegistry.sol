// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/**
 * @title NodeRegistry
 * @author Lifeworld
 */
contract NodeRegistry is INodeRegistry {

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /**
     * @dev Emit an event when a new schema is registered
     *
     *      Schemas are unique hash identifiers that nodeIds anchor themselves to upon initialization
     *      NodeIds that are initialized without providing an existing schema will be considered invalid
     *
     * @param sender        Address of the account calling `registerSchema()`
     * @param schema        Hash value for the unique schema being registered
     * @param data          Data to associate with the registration of a new schema
     */
    event RegisterSchema(address indexed sender, bytes32 indexed schema, bytes data);

    /**
     * @dev Emit an event when a new node is initialized
     *
     *      NodeIds provide targets for messaging strategies. It is recommended
     *      that all messaging strategies include nodeId as a field to provide
     *      affective filtering of the entire data set produced via the registry
     *
     * @param sender        Address of the account calling `initializeNode()`
     * @param nodeId        NodeId being initialized
     * @param data          Data to associate with the initialization of a new nodeId
     */
    event InitializeNode(address indexed sender, uint256 indexed nodeId, bytes data);

    /**
     * @dev Emit an event when a new update is sent
     *
     *      Updates allow for the transmission of data to existing nodes. The sender field in the
     *      UpdateNode event allows for filtering by accounts such as app-level signers,
     *      while the updateId field allows for a universal-id mechanism to identify
     *      given updates regardless of the nodeId they are targeting
     *
     * @param sender        Address of the account calling `updateNode()`
     * @param updateId      The updateId being generated
     * @param data          Data to transmit in the update
     */
    event UpdateNode(address indexed sender, uint256 indexed updateId, bytes data);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public schemaCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public updateCount;

    //////////////////////////////////////////////////
    // SCHEMA REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function registerSchema(bytes calldata data) external returns (bytes32 schema) {
        // Increments schemaCount before hash generation
        schema = keccak256(abi.encode(block.chainid, address(this), ++schemaCount));
        emit RegisterSchema(msg.sender, schema, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerSchemaBatch(bytes[] calldata datas) external returns (bytes32[] memory schemas) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        schemas = new bytes32[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Increments schemaCount before hash generation
            schemas[i] = keccak256(abi.encode(block.chainid, address(this), ++schemaCount));
            // Emit for indexing
            emit RegisterSchema(sender, schemas[i], datas[i]);
        }
    }

    //////////////////////////////////////////////////
    // NODE REGISTRATION
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function initializeNode(bytes calldata data) external returns (uint256 nodeId) {
        // Increments nodeCount before event emission
        nodeId = ++nodeCount;
        emit InitializeNode(msg.sender, nodeId, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function initializeNodeBatch(bytes[] calldata datas) external returns (uint256[] memory nodeIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        nodeIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount before event emission
            emit InitializeNode(sender, nodeIds[i], datas[i]);
        }
    }

    //////////////////////////////////////////////////
    // NODE MESSAGING
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function updateNode(bytes calldata data) external returns (uint256 updateId) {
        // Increments updateCount before event emission
        updateId = ++updateCount;
        emit UpdateNode(msg.sender, updateId, data);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function updateNodeBatch(bytes[] calldata datas) external returns (uint256[] memory updateIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Assign return data length
        updateIds = new uint256[](datas.length);
        for (uint256 i; i < datas.length; ++i) {
            // Increment updateCount and copy to return variable
            updateIds[i] = ++updateCount;
            // Emit Message event
            emit UpdateNode(sender, updateIds[i], datas[i]);
        }
    }
}

/*

    *** SCRYPTING ***


    What we need
    - Two types of actions
        - Initialize a node
        - Update a node
    - Initializing a node
        - need to define what type of node it is
        - this can be done by declaring the schema hash
        - beyond that, can send as many messages to the node as desired
    - Updating a node
        - need to identify what node you are targeting
        - this can be done by declaring the nodeId you are targeting
        - beyond that, can send as many messages to the node as desired

    What do the functions look like
    - function initializeNode(bytes32 schema, bytes[] messages) external returns (uint256 nodeId)
    - function updateNode(uint256 nodeId, bytes[] messages) external returns (uint256 updateId)

    What do `Messages` look like
    - struct Message {
        uint256 id;     // what user is submitting the message
        uint256 type;   // what type of message is it
        bytes body;     // what are the contents of the message
    }

    Examples
    - Registering a Publication Node
        - assumptions
            - publicationSchema = 0xPUB
            - user ids 1, 2, 3 are valid
        - data preparation
            - bytes accessControl = abi.encode(Message{
                userId: 1,
                type: 001   // the first message to each node must be a 0 message, which signifies access control
                body: abi.encode([1], [2, 3]) // this is the body for `adminWithMembers` strat that corresponds with msg type 001
            })
            - bytes setUri = abi.encode(Message{
                userId: 1,
                type: 101  // types of 100 are used for Publication messages. this one means "update uri"
                body: abi.encode("myIpfsCid") // this is the body for strat that corresponds with msg type 101
            })
            - bytesMessageArray = new bytes[](2)
                - bytesMessageArray[0] = accessControl
                - bytesMessageArray[1] = setUri
        - function call
            - nodeRegistry.initializeNode(publicationSchema, bytesMessageArray)        
    - Registering a Channel Node
        - assumptions
            - publicationSchema = 0xCHA
            - user ids 1, 2, 3 are valid
        - data preparation
            - bytes accessControl = abi.encode(Message{
                userId: 1,
                type: 001   // the first message to each node must be a 0 message, which signifies access control
                body: abi.encode([1], [2, 3]) // this is the body for `adminWithMembers` strat that corresponds with msg type 001
            })
            - bytes addItem = abi.encode(Message{
                userId: 1,
                type: 201  // types of 200 are used for Channel messages. this one means "add item to channel"
                body: abi.encode(Pointer{  // this is the body for `addItem` strat that corresponds with type 201
                    chainId: 420,
                    id: 1,
                    target: address(nodeRegistry),
                    hasId: true
                })
            })
            - bytesMessageArray = new bytes[](2)
                - bytesMessageArray[0] = accessControl
                - bytesMessageArray[1] = addItem
        - function call
            - nodeRegistry.initializeNode(channelSchema, bytesMessageArray)  

    Narrator: 
    ok this is great, we can now initialize both channel nodes + publication nodes
    using the same schema. but right now this would require two transactions, 
    can we make a batch function to deal with this?

    What does Batch function look like?
    - batchInitializeNode(bytes32[] schemas, bytes[][] messages) external returns (uint256[] nodeIds)

    Examples
        - assumptions
            - publicationSchema = 0xPUB
            - publicationSchema = 0xCHA
            - user ids 1, 2, 3 are valid
        - data preparation
            *
            ** pub node    
            *
            - bytes pubNode_AccessControl = abi.encode(Message{
                userId: 1,
                type: 001   // the first message to each node must be a 0 message, which signifies access control
                body: abi.encode([1], [2, 3]) // this is the body for `adminWithMembers` strat that corresponds with msg type 001
            })    
            - bytes setUri = abi.encode(Message{
                userId: 1,
                type: 101  // types of 100 are used for Publication messages. this one means "update uri"
                body: abi.encode("myIpfsCid") // this is the body for strat that corresponds with msg type 101
            })            
            - pubNode_MessageArray = new bytes[](2)
                - pubNode_MessageArray[0] = pubNode_AccessControl
                - pubNode_MessageArray[1] = setUri         
            *
            ** channel node    
            *
            - bytes channelNode_AccessControl = abi.encode(Message{
                userId: 1,
                type: 001   // the first message to each node must be a 0 message, which signifies access control
                body: abi.encode([1], []) // this is the body for `adminWithMembers` strat that corresponds with msg type 001
            })    
            - bytes addItem = abi.encode(Message{
                userId: 1,
                type: 201  // types of 200 are used for Channel messages. this one means "add item to channel"
                body: abi.encode(Pointer{  // this is the body for `addItem` strat that corresponds with type 201
                    chainId: 420,
                    id: 1,
                    target: address(nodeRegistry),
                    hasId: true
                })
            })            
            - channelNode_MessageArray = new bytes[](2)
                - channelNode_MessageArray[0] = channelNode_AccessControl
                - channelNode_MessageArray[1] = addItem      
            *
            ** combined message
            *      
            - bytes[][] combinedArray = new bytes[][](2)
                - combinedArray[0] = new bytes[0](2)
                - combinedArray[0] = pubNode_MessageArray // this is an array of length 2
                - combinedArray[1] = new bytes[0](2)
                - combinedArray[1] = channelNode_MessageArray // this is an array of length 2                
        - function call
            - function batchInitializeNode(bytes[] schemas, bytes[][] messages) external returns (uint256[] nodeIds) {
                if (schemas.length != messages.length) revert Array_Length_Mismatch();
                for (uint256 i; i < schemas.length; ++i) {
                    emit NodeInitialized(
                        sender: msg.sender,     // type address
                        schema: schemas[i],     // type bytes32
                        message: messages[i]    // type bytes[]
                    )
                }
            }
            - nodeReigstry.batchInitializeNode(
                [publicationSchema, channelSchema], // type bytes32[]
                combinedArray                       // type bytes[][]
            )

    Narrator: 
    ok this is great. maybe gas heavy, we should test this. node updates will work exactly the same,
    except instead of declaring bytes32 schemas to initialize ndoes to, we declare uint256 nodeIds to update.
    the question that comes to mind now is, what if we want to both initialize AND message nodes in one
    function call? is there a way to do batching to process it in one txn to save costs?
    
    initial ideas:
     - nodes can not be updated in the same timestamp/blocknumber as they are initialized
        - this is somewhat to account for indexing lag, but also to ensure that access control
          is always set prior to an update being received, and bc access control is calculated offchain,
          a specification enforced lag of at least 1 can accomplish this
*/