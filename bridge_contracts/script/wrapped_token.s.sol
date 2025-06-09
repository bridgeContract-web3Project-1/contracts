// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Erc20_bridged_tokekn} from "../src/wrapperEthToken.sol";

contract DeployMyToken is Script {
    function run() external {

        vm.startBroadcast();

        Erc20_bridged_tokekn token = new Erc20_bridged_tokekn(); // 1M tokens with 18 decimals
        console.log("Token deployed to:", address(token));

        vm.stopBroadcast();
    }
}