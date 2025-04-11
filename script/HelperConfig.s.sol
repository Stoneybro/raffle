// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkTokens.sol";
abstract contract CodeConstraints {
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    uint96 constant BASE_FEE = 0.25 ether;
    uint96 constant GAS_PRICE = 1e9;
    int256 constant WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is CodeConstraints, Script {
    struct NetworkConfig {
        address _vrfCoordinator;
        uint256 entranceFee;
        bytes32 keyhash;
        uint256 subscriptionId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        address link;
    }
    NetworkConfig private localNetworkConfig;
    error HelperConfig__InvalidChain();

    function getConfigbyChainId(
        uint256 blockChainId
    ) private returns (NetworkConfig memory) {
        if (blockChainId == SEPOLIA_CHAIN_ID) {
            return getSepoliaEthConfig();
        } else if (blockChainId == LOCAL_CHAIN_ID) {
            return getAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChain();
        }
    }
    function getConfig() public returns( NetworkConfig memory) {
        return getConfigbyChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                _vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                entranceFee: 0.01 ether,
                keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                link:0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock = new VRFCoordinatorV2_5Mock(
            BASE_FEE,
            GAS_PRICE,
            WEI_PER_UNIT_LINK
        );
        LinkToken linkToken=new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            _vrfCoordinator: address(mock),
            entranceFee: 0.01 ether,
            keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            requestConfirmations: 3,
            callbackGasLimit: 100000,
            numWords: 1,
            link:address(linkToken)
        });
        return localNetworkConfig;
    }
}
