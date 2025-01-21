// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CV} from "../src/CV.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        new CV(msg.sender);
        vm.stopBroadcast();
    }
}
