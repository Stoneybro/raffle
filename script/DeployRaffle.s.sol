// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/interactions.s.sol";
contract DeployRaffle is Script {
    function run() public {
        
    }
    function deployContract() public  returns (Raffle,HelperConfig) {
        HelperConfig helperConfig=new HelperConfig();
        HelperConfig.NetworkConfig memory config=helperConfig.getConfig();
        if (config.subscriptionId==0) {
            CreateSubscription createSubscription=new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator)=createSubscription.createSubscription(config.vrfCoordinator);
        }
        vm.startBroadcast();
        Raffle raffle=new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callBackGasLimit,
            config.subscriptionId
        );
        vm.stopBroadcast();
        return(raffle,helperConfig);
    }
}