![image](https://github.com/user-attachments/assets/0836c1dc-61ed-4431-9f8c-1a46daaf4eeb)


<h2>🌉 Cross-Chain Bridge Infrastructure: ETH ⇄ Avalanche</h2>

<p>
  We’ve built a bridge infrastructure that allows users to move ETH from the Ethereum blockchain to the Avalanche blockchain and receive equivalent wrapped ETH tokens on Avalanche. This enables users to interact with dApps on Avalanche using their ETH.
</p>

<h3>🔗 Smart Contracts Overview</h3>

<p>We use <strong>three smart contracts</strong> in our system:</p>

<ol>
  <li><strong>ETH Contract</strong> – Deployed on Ethereum. It receives ETH deposits from users.</li>
  <li><strong>Wrapper Contract</strong> – Deployed on Avalanche. It handles minting of wrapped ETH tokens.</li>
  <li><strong>Avalanche Contract</strong> – Also on Avalanche. It verifies cross-chain messages and handles confirmations.</li>
</ol>

<h3>🚀 Current Functionality</h3>

<p>As of now, we support the <strong>Lock and Mint</strong> flow. (Burn and Unlock are coming soon.)</p>

<hr>

<h3>🔄 Step-by-Step Process</h3>

<ol>
  <li>
    <strong>User Initiates Transfer</strong><br>
    The user visits our dApp and initiates a transfer by sending ETH to our Ethereum contract.
  </li>

  <li>
    <strong>Lock Event Emitted</strong><br>
    After receiving ETH, the Ethereum contract emits an event containing a <code>lockId</code>, the <strong>user's address</strong>, and the <strong>amount</strong>.<br>
    This event also triggers a message via <strong>Chainlink CCIP</strong> to Avalanche’s <code>_ccipReceive</code> function.
  </li>

  <li>
    <strong>CCIP Message Handling</strong><br>
    On the Avalanche side, we track confirmations using:
    <pre><code>mapping(bytes32 => mapping(address => mapping(uint256 => uint8))) confirmations;</code></pre>
    When <code>_ccipReceive</code> is called, it updates the mapping and increases the confirmation count.
  </li>

  <li>
    <strong>Backend Indexing</strong><br>
    Once the ETH transaction is complete, the <strong>frontend</strong> calls our <strong>backend API</strong>.<br>
    The backend reads logs from blocks <code>[current - 1, current + 1]</code>, verifies the event, and sends a transaction to Avalanche’s <code>backend_confirmation()</code> function.
  </li>

  <li>
    <strong>Confirm and Mint</strong><br>
    In <code>backend_confirmation()</code>, the contract:
    <ul>
      <li>Checks if the mapping contains the <code>lockId</code>, <code>user</code>, and <code>amount</code>.</li>
      <li>If valid, increases the confirmation count.</li>
      <li>Once confirmation reaches <strong>2</strong>, it automatically calls the <code>mint</code> function to mint wrapped ETH to the user.</li>
    </ul>
  </li>
</ol>

<hr>

<h3>🔜 Coming Soon</h3>

<p>
  We will soon implement the <strong>Burn and Unlock</strong> mechanism, allowing users to return wrapped ETH and unlock original ETH on Ethereum.
</p>

<hr>

<p>
  This setup ensures a secure, verifiable, and user-friendly way to move assets between chains using a combination of smart contracts, backend verification, and Chainlink's CCIP messaging.
</p>

