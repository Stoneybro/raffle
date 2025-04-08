// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/raffle.sol";
import {Script} from "forge-std/Script.sol";
import {CreateSubscription, FundSubscription,AddConsumer} from "script/interactions.s.sol";
contract DeployRaffle is Script {
    function run() external returns (Raffle,HelperConfig) {

        HelperConfig helperConfig=new HelperConfig();
        HelperConfig.NetworkConfig memory config=helperConfig.getConfig();
        if (config.subId==0) {
            CreateSubscription subscription=new CreateSubscription();
            (config.vrfCoordinator, config.subId)=subscription.createSubscription();
            FundSubscription fundSubscription= new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator,config.subId,config.link);
        }
        vm.startBroadcast();
        Raffle raffle=new Raffle(
            config.keyHash,
            config.subId,
            config.requestConfirmations,
            config.callbackGasLimit,
             config.numWords,
             config.vrfCoordinator,
             config.entranceFee,
             config.interval
        );
        vm.stopBroadcast();
        AddConsumer addConsumer=new AddConsumer();
        addConsumer.addConsumer(address(raffle),config.vrfCoordinator,config.subId);

        return (raffle,helperConfig);
    }
}
        // bytes32 keyHash;
        // uint256 subId;
        // uint16 requestConfirmations;
        // uint32 callbackGasLimit;
        // address vrfCoordinator