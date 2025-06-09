// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
// import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract Eth_bridge_contract {  

    constructor() {}

    event lockedEther(address indexed user_address, uint256 amount , bytes32 indexed lockId);
    

    // maximum allowed locking ether is 10 eth , because if any failure happens then , anything bug shouldnt happne
    uint256 max_eth_lock = 10;
    uint256 wai_in_one_eth = 1000000000000000000;

    // we will store wai/smallest unit
    uint256 totalEth = 0;

    // Custom errors to provide more descriptive revert messages.
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 messageID,
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        string text, // The text being sent.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the CCIP message.
    );

    // initiallizing the router on the this blockchain router =? that is this sepolia eth chain router
    IRouterClient private s_router = IRouterClient(0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);

    // initiallizing the link token contract on sepolia testnet
    LinkTokenInterface private s_linkToken = LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    function lockEth() external payable {
        require( msg.value <=0, "please enter amount greater than zero" );
        require( msg.value >= max_eth_lock * wai_in_one_eth, "you can only lock eth less tha 10" );

        // generate a random id
        // 1 address at a specific timestamp cannot send 2 txns, so this id will we unique
        bytes32 lockID = keccak256(abi.encodePacked(msg.sender, block.timestamp , msg.value));

            // calculating sepolia eth fess required to send message to avalanche
        uint256 fees = calculateEthFees(msg.value , msg.sender , lockID , 16015286601757825753 );
         if (msg.value <= fees) {
            revert NotEnoughBalance(msg.value ,fees);
        }


        // total eth will be in wei , in smallest uint of eth
        // we will deduct fees from the user locked eth only
        totalEth += (msg.value - fees) * wai_in_one_eth;


        emit lockedEther(msg.sender, msg.value , lockID);



        createConfirmation_from_chainlinkCCIP(msg.value , msg.sender , lockID , fees);
    }

    function createConfirmation_from_chainlinkCCIP(uint256 amount , address  user_Add , bytes32 lockID , uint256 fees) internal {

        // avalanche fuji /testnet chain selector
        uint64 destinationChainSelector = 16015286601757825753;

        // message to be sent
        bytes memory messsage = abi.encode(uint256(amount), address(user_Add), bytes32(lockID));

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            // todo , add the avalanche contract address
            receiver: abi.encode(address(0x123333)), // ABI-encoded receiver address
            data : messsage, // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000, // Gas limit for the callback on the destination chain
                    allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                })
            ),
            // Set the feeToken  address, indicating LINK will be used for fees
            feeToken: address(0)
        });

          // Send message and pay with ETH
        bytes32 messageId = s_router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit MessageSent(
            messageId , 
            destinationChainSelector,
            address(0x123333),
            string(messsage),
            address(s_linkToken),
            fees
        );
    }


// here we are just constructing message ande checking how much in eth would be required to send this message from eth to avalanche
    function calculateEthFees( uint256 amount , address user_Add , bytes32 lockID ,  uint64 destinationChainSelector) view internal returns(uint256){

        bytes memory messsage = abi.encode(uint256(amount), address(user_Add), bytes32(lockID));

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            // todo , add the avalanche contract address
            receiver: abi.encode(address(0x123333)), // ABI-encoded receiver address
            data : messsage, // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: 200_000, // Gas limit for the callback on the destination chain
                    allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                })
            ),
            // Set the feeToken  address, indicating eth sepolia will be used for fees
            feeToken: address(0)
        });

        // Get the fee required to send the message
        uint256 fees = s_router.getFee(destinationChainSelector, evm2AnyMessage);

        return fees;

    }
}
