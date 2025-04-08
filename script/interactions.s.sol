// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.16;
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkTokens.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script {
    function run() external {
        createSubscription();
    }

    function createSubscription() public returns (address, uint256) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        return (vrfCoordinator, subId);
    }
}

contract FundSubscription is Script {
    uint256 private constant FUND_AMOUNT = 3 ether; //3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subId;
        address linkToken=helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator,subId,linkToken);
    }
    function fundSubscription(address vrfCoordinator,uint256 subId,address linkToken) public {
       if (block.chainid==31337) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId,FUND_AMOUNT);
        vm.stopBroadcast();
       } else {
        vm.startBroadcast();
        LinkToken(linkToken).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subId));
        vm.stopBroadcast();
       }
    }
}
contract AddConsumer is Script{
    function addConsumerUsingConfig(address mostRecentlyDeployed)  public {
                HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subId;
        address linkToken=helperConfig.getConfig().link;
        addConsumer(mostRecentlyDeployed,vrfCoordinator,subId);
    }
    function addConsumer(address contractToAddtoVrf,address vrfCoordinator, uint256 subId)  public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId,contractToAddtoVrf);
        vm.stopBroadcast();
    }
    function run()  external {
        address mostRecentlyDeployed= DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
