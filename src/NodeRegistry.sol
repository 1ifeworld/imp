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
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide targets for messaging strategies. To identify
     *      different types of nodes, you can emit a bytes32 hash upon its registration
     *
     * @param sender        Address of the account calling `register()`
     * @param schema        Schema to register node as
     * @param nodeId        NodeId registered in transaction
     * @param messages      Messages to send to node during registration
     */
    event Register(address indexed sender, bytes32 indexed schema, uint256 indexed nodeId, bytes[] messages);

    /**
     * @dev Emit an event when a new update is sent
     *
     *      Updates allow for the transmission of data to existing nodes
     *
     * @param sender        Address of the account calling `update()`
     * @param nodeId        Id of node to target
     * @param messages      Messages to send to node during update
     */
    event Update(address indexed sender, uint256 indexed nodeId, bytes[] messages);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    //////////////////////////////////////////////////
    // REGISTER
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function register(bytes32 schema, bytes[] calldata messages) external returns (uint256 nodeId) {
        // Increments nodeCount
        nodeId = ++nodeCount;
        emit Register(msg.sender, schema, nodeId, messages);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerBatch(bytes32[] calldata schemas, bytes[][] calldata messages) external returns (uint256[] memory nodeIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Create array to track nodeIds for return
        nodeIds = new uint256[](schemas.length);
        // Loop through data
        for (uint256 i; i < schemas.length; ++i) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount
            emit Register(sender, schemas[i], nodeIds[i], messages[i]);
        }
    }

    //////////////////////////////////////////////////
    // UPDATE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function update(uint256 nodeId, bytes[] calldata messages) external {
        emit Update(msg.sender, nodeId, messages);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function updateBatch(uint256[] calldata nodeIds, bytes[][] calldata messages) external {
        // Cache msg.sender
        address sender = msg.sender; 
        // Loop through data                
        for (uint256 i; i < nodeIds.length; ++i) {
            // Emit Message event
            emit Update(sender, nodeIds[i], messages[i]);
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