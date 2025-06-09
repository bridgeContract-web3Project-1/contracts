![image](https://github.com/user-attachments/assets/0836c1dc-61ed-4431-9f8c-1a46daaf4eeb)


🌉 Cross-Chain Bridge Infrastructure: ETH ⇄ Avalanche
We’ve built a bridge infrastructure that allows users to move ETH from the Ethereum blockchain to the Avalanche blockchain and receive equivalent wrapped ETH tokens on Avalanche. This enables users to interact with dApps on Avalanche using their ETH.

🔗 Smart Contracts Overview
We use three smart contracts in our system:

ETH Contract – Deployed on Ethereum. It receives ETH deposits from users.

Wrapper Contract – Deployed on Avalanche. It handles minting of wrapped ETH tokens.

Avalanche Contract – Also on Avalanche. It verifies cross-chain messages and handles confirmations.

🚀 Current Functionality
As of now, we support the Lock and Mint flow. (Burn and Unlock are coming soon.)

🔄 Step-by-Step Process
User Initiates Transfer

The user visits our dApp and initiates a transfer by sending ETH to our Ethereum contract.

Lock Event Emitted

After receiving ETH, the Ethereum contract emits an event containing a unique lockId, the user's address, and the amount.

This event also triggers a message to be sent using Chainlink CCIP to the Avalanche contract's _ccipReceive function.

CCIP Message Handling

On the Avalanche side, we have a mapping structure:

solidity
Copy
Edit
mapping(bytes32 => mapping(address => mapping(uint256 => uint8))) confirmations;
This tracks how many confirmations have been received for a specific lockId, user, and amount.

When _ccipReceive is called, it updates the mapping and increments the confirmation count.

Backend Indexing

Once the ETH transaction is complete, the frontend calls our backend API.

The backend reads logs from blocks [current - 1, current + 1], verifies the event, and if everything checks out, it sends a transaction to the Avalanche contract's backend_confirmation() function.

Confirm and Mint

Inside backend_confirmation():

The contract checks if the mapping already has the lockId, user, and amount.

If valid, it increments the confirmation count.

When the confirmation count reaches 2, the contract automatically calls the mint function, minting wrapped ETH tokens to the user's Avalanche address.

🔜 Coming Soon
We will soon implement the Burn and Unlock mechanism, which will allow users to send wrapped ETH back to Ethereum and unlock their original ETH.
