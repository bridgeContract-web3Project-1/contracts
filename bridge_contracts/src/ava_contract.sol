// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";

contract avalanche_bridge_contract is CCIPReceiver {
    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        string text // The text that was received.
    );

    // avalanche fuji router address
    constructor() CCIPReceiver(0xF694E193200268f9a4868e4Aa017A0118C9a8177) {}

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    // is txn for this lockid  done ?
    mapping(bytes32 => bool) public is_tx_done;

    // is this lockid => account == amount == confirmations( 2 ) ? , then only mint function will be called
    // 1 confrimation done by the chainlink and other by backend
    mapping(bytes32 => mapping(address => mapping(uint256 => uint8)))
        internal lockId_account_confirmations;

    // this will be called by either backend_confirmation or chailink reciever function only
    function mint_wrapped_token(
        address user_add,
        bytes32 lockId,
        uint amount
    ) internal {
        require(!is_tx_done[lockId], "transaction already completed");
        require(
            lockId_account_confirmations[lockId][user_add][amount] == 2,
            "not enough confirmations"
        );

        is_tx_done[lockId] = true;
        // wrappedEthtoken_contract.mint(user_add , amount);
    }

    // this will called by the eth contract ccip send function
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId; // fetch the messageId

        (uint256 amount, address userAddress, bytes32 lockId) = abi.decode(
            any2EvmMessage.data,
            (uint256, address, bytes32)
        ); 

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            abi.decode(any2EvmMessage.sender, (address)), // abi-decoding of the sender address,
            abi.decode(any2EvmMessage.data, (string))
        );

        if (lockId_account_confirmations[lockId][userAddress][amount] == 0) {
            lockId_account_confirmations[lockId][userAddress][amount] = 1;
        } else if (
            lockId_account_confirmations[lockId][userAddress][amount] == 1
        ) {
            lockId_account_confirmations[lockId][userAddress][amount] = 2;
            mint_wrapped_token(userAddress, lockId, amount);
        }
    }

    function backend_confirmation(
        address account_add,
        bytes32 lockid,
        uint256 amount
    ) public {
        if (lockId_account_confirmations[lockid][account_add][amount] == 0) {
            lockId_account_confirmations[lockid][account_add][amount] = 1;
        } else if (
            lockId_account_confirmations[lockid][account_add][amount] == 1
        ) {
            lockId_account_confirmations[lockid][account_add][amount] = 2;
            mint_wrapped_token(account_add, lockid, amount);
        }
    }
}
