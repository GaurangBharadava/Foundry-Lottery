// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./interaction.s.sol";

contract DeployRaffle is Script {
    // function deployContract() external returns (Raffle, HelperConfig) {
    //     HelperConfig helperConfig = new HelperConfig();

    //     HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    //     if (config.subscriptionId == 0) {
    //         //create subscription.
    //         CreateSubscription createSubscription = new CreateSubscription();
    //         (config.subscriptionId, config.vrfCoordinator) = createSubscription
    //             .createSubscription(config.vrfCoordinator);

    //         FundSubscription fundSubscription = new FundSubscription();
    //         fundSubscription.fundSubscription(
    //             config.vrfCoordinator,
    //             config.subscriptionId,
    //             config.link
    //         );
    //     }

    //     vm.startBroadcast();
    //     Raffle raffle = new Raffle(
    //         config.entranceFee,
    //         config.interval,
    //         config.vrfCoordinator,
    //         config.gasLane,
    //         config.subscriptionId,
    //         config.callbackGasLimit
    //     );
    //     vm.stopBroadcast();

    //     AddConsumer addConsumer = new AddConsumer();
    //     addConsumer.addConsumer(
    //         address(raffle),
    //         config.vrfCoordinator,
    //         config.subscriptionId
    //     );

    //     return (raffle, helperConfig);
    // }

    //Abov code is not wokking fine because of some silly mistake, appropriate code written in run function.

    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            //create subscription.
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        return (raffle, helperConfig);
    }
}
