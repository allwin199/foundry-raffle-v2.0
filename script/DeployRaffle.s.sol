// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        Raffle raffle;

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            uint64 subscriptionId
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            callbackGasLimit,
            subscriptionId
        );
        vm.stopBroadcast();

        return raffle;
    }
}
