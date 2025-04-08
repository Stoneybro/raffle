// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkTokens.sol";
contract HelperConfig is Script {
    struct NetworkConfig {
        bytes32 keyHash;
        uint256 subId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        address vrfCoordinator;
        uint256 entranceFee;
        uint256 interval;
        address link;
    }
    uint96 private constant BASE_FEE = 0.25 ether;
    uint96 private constant GAS_PRICE = 1e9;
    int256 private constant WEI_PER_UNIT_LINK = 4e15;
    uint256 private constant SEPOLIA_CHAINID=11155111;
    uint256 private constant LOCAL_CHAINID=31337;
    NetworkConfig private localNetworkConfigs;

    error HelperConfig__invalidChain();
    

    function getConfigByChainId(uint256 chainid) private returns (NetworkConfig memory)  {
        if (chainid==SEPOLIA_CHAINID) {
            return getSepoliaEthConfig();
        }else if(chainid==LOCAL_CHAINID){
            return createOrGetAnvilEthConfig();
        }else{
            revert HelperConfig__invalidChain();
        }
    }
    function getConfig() external returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subId: 0,
                requestConfirmations: 3,
                callbackGasLimit: 2500000,
                numWords: 1,
                vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
                 entranceFee:0.025 ether,
                 interval:100,
                 link:0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function createOrGetAnvilEthConfig()
        public
        returns (NetworkConfig memory)
    {
        if (localNetworkConfigs.vrfCoordinator != address(0)) {
            return localNetworkConfigs;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE,
            WEI_PER_UNIT_LINK
        );
        LinkToken linkToken=new LinkToken();
        vm.stopBroadcast();
        localNetworkConfigs = NetworkConfig({
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 0,
            requestConfirmations: 3,
            callbackGasLimit: 2500000,
            numWords: 1,
            vrfCoordinator: address(mock),
            entranceFee:0.025 ether,
            interval:100,
            link:address(linkToken)
        });
        return localNetworkConfigs;
    }
}
