// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Erc20_bridged_tokekn is ERC20 {
    constructor() ERC20("WrappedETH", "wETH") {}

    // give the value in wai(10^18)
    function mint_wETH(uint256 value, address account) public {
        _mint(account, value);
    }

    function burn_wETH(uint256 value, address account) public {
        _burn(account, value);
    }
}
