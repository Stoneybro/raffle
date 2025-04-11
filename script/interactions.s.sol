// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/raffle.sol";
import {HelperConfig, CodeConstraints} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkTokens.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script {
    function createSubscriptionWithConfig() public returns (address, uint256) {
        HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = createSubscriptionFunction(VrfCoordinator);
        return (VrfCoordinator, subscriptionId);
    }

    function createSubscriptionFunction(
        address vrfCoordinator
    ) public returns (uint256) {
        vm.startBroadcast();
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return subscriptionId;
    }
}

contract FundSubscription is CodeConstraints, Script {
    uint256 constant FUNDING_AMOUNT = 3000 ether;

    function fundSubscriptionWithConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address link=helperConfig.getConfig().link;
        fundSubscriptionFunction(
            VrfCoordinator,
            subscriptionId,      
            link
        );
    }

    function fundSubscriptionFunction(
        address vrfCoordinator,
        uint256 subscriptionId,
        address link
    ) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,FUNDING_AMOUNT*100);
            vm.stopBroadcast();
        }else{
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator,FUNDING_AMOUNT,abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
   function addConsumerWithConfig() public {
      HelperConfig helperConfig = new HelperConfig();
        address VrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address recentlyDeployed=DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
        addConsumerFunction(VrfCoordinator,subscriptionId,recentlyDeployed);
   }
      function addConsumerFunction(address vrfCoordinator,uint256 subscriptionId, address recentContract) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId,recentContract);
        vm.stopBroadcast();
    
   }
}
