// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig.NetworkConfig config;
    address immutable i_player = makeAddr("user");
    address _vrfCoordinator;
    uint256 entranceFee;
    bytes32 keyhash;
    uint256 subscriptionId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    uint256 private immutable interval = 60;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, config) = deployRaffle.deployRaffleContract();
        vm.deal(i_player, 100 ether);
        _vrfCoordinator = config._vrfCoordinator;
        entranceFee = config.entranceFee;
        keyhash = config.keyhash;
        subscriptionId = config.subscriptionId;
        requestConfirmations = config.requestConfirmations;
        callbackGasLimit = config.callbackGasLimit;
        numWords = config.numWords;
    }

    modifier raffleEntered() {
        vm.prank(i_player);
        raffle.enterRaffle{value: 0.1 ether}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_EntranceFee_WhenLessThanEntranceFeesIsFunded_ShouldRevert()
        external
    {
        vm.prank(i_player);
        vm.expectRevert(Raffle.Raffle__InsufficientFunds.selector);
        raffle.enterRaffle();
    }

    function test_RafflePlayersArray_WhenPlayerFunds_ArrayUpdates() external {
        vm.prank(i_player);
        raffle.enterRaffle{value: 0.1 ether}();
        address newPlayer = raffle.getPlayerArray(0);
        assert(newPlayer == i_player);
    }

    function test_RaffleState_WhenRaffleIsCalculating_EnterRaffleReverts()
        external
        raffleEntered
    {
        raffle.performUpkeep("");
    }

    function test_UpkeepNeeded_checkIfAllValuesIsTrue_ShouldBeSuccesfull()
        external
        raffleEntered
    {
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");
        //  bool whenRaffleEntered = upKeepNeeded;
        assert(upKeepNeeded);
    }

    function test_performUpkeep_EmitsRequestId_RecordLogs()
        public
        raffleEntered
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);
    }

    function test_FufillRandomWords_CanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequest
    ) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(
            randomRequest,
            address(raffle)
        );
    }

    function test_FufillRandomWords_PickAndPaywinnerAndResetArray()
        external
        raffleEntered
    {
        uint256 raffleEntrants = 4;
        for (uint i = 1; i < raffleEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, 100 ether);
            raffle.enterRaffle{value: 1 ether}();
        }
        address expectedWinner = address(1);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

    }
}
