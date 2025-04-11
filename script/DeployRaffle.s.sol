// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/raffle.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "script/interactions.s.sol";
contract DeployRaffle is Script {
    function run() external {
        deployRaffleContract();
    }
    function deployRaffleContract() public returns(Raffle,HelperConfig.NetworkConfig memory) {
        HelperConfig helperConfig=new HelperConfig();
        HelperConfig.NetworkConfig memory config=helperConfig.getConfig();

        if (config.subscriptionId==0) {
            CreateSubscription Csubscription=new CreateSubscription();
            (config._vrfCoordinator,config.subscriptionId)=Csubscription.createSubscriptionWithConfig();
            FundSubscription Fsubscriptions=new FundSubscription();
            Fsubscriptions.fundSubscriptionFunction(config._vrfCoordinator,config.subscriptionId,config.link);
        }
        vm.startBroadcast();

        Raffle raffle= new Raffle(
            config._vrfCoordinator,
            config.entranceFee,
            config.keyhash,
            config.subscriptionId,
            config.requestConfirmations,
            config.callbackGasLimit,
            config.numWords
        );
        vm.stopBroadcast();
            
        AddConsumer addConsumer=new AddConsumer();
        addConsumer.addConsumerFunction(config._vrfCoordinator,config.subscriptionId,address(raffle));
        return (raffle,config);
    }
}