// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscription(
        address _vrfCoordinator
    ) public returns (uint64) {
        console2.log("Creating subscription on ChainId: ", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console2.log("Your SubId is: ", subId);
        return subId;
    }

    function subscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator);
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
        address _link
    ) public {
        console2.log("Funding Subscription: ", _subId);
        console2.log("Using vrfCoordinator: ", _vrfCoordinator);
        console2.log("On ChainId: ", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
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
            address link
        ) = helperConfig.activeNetworkConfig();
        return fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function run() external {
        return fundSubscriptionUsingConfig();
    }
}
