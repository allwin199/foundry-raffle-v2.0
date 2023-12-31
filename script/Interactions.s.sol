// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscription(
        address _vrfCoordinator,
        uint256 _deployer
    ) public returns (uint64) {
        console2.log("Creating subscription on ChainId: ", block.chainid);
        vm.startBroadcast(_deployer);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console2.log("Your SubId is: ", subId);
        return subId;
    }

    function subscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , , uint256 deployer) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployer);
    }

    function run() external returns (uint64) {
        return subscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subId,
        address _link,
        uint256 _deployer
    ) public {
        console2.log("Funding Subscription: ", _subId);
        console2.log("Using vrfCoordinator: ", _vrfCoordinator);
        console2.log("On ChainId: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast(_deployer);
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_link).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            uint64 subscriptionId,
            address link,
            uint256 deployer
        ) = helperConfig.activeNetworkConfig();
        return fundSubscription(vrfCoordinator, subscriptionId, link, deployer);
    }

    function run() external {
        return fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address _vrfCoordinator,
        uint64 _subId,
        address _raffle,
        uint256 _deployer
    ) public {
        console2.log("Adding Consumer Contract ", _raffle);
        console2.log("Using VrfCoordinator ", _vrfCoordinator);
        console2.log("On ChainId: ", block.chainid);

        vm.startBroadcast(_deployer);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
    }

    function addConsumerConfig(address _raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            ,
            uint64 subscriptionId,
            ,
            uint256 deployer
        ) = helperConfig.activeNetworkConfig();
        return addConsumer(vrfCoordinator, subscriptionId, _raffle, deployer);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        return addConsumerConfig(raffle);
    }
}
