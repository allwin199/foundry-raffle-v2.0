// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            uint64 subscriptionId,
            address link,
            uint256 deployer
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            /// @dev create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployer
            );

            /// @dev funding the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployer
            );
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            callbackGasLimit,
            subscriptionId
        );
        vm.stopBroadcast();

        /// @dev After deploying the raffle contract, add this contract as consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployer
        );

        return (raffle, helperConfig);
    }
}
