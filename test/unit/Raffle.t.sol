// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callBackGasLimit;
    uint256 subscriptionId;
    address public immutable i_player = makeAddr("i_player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deploy = new DeployRaffle();
        (raffle, helperConfig) = deploy.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callBackGasLimit = config.callBackGasLimit;
        vm.deal(i_player, STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState() external view {
        assert(uint256(raffle.getRaffleState()) == 0);
    }

    function testRevertsWhenUserDoesntPay() external {
        //Arrange
        vm.prank(i_player);
        //Act //Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleArrayUpdates() external {
        //Arrange
        vm.prank(i_player);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert
        assert(raffle.getPlayer(0) == i_player);
    }

    function testEnterRaffleEmitsEvent() external {
        //Arrange
        vm.prank(i_player);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(i_player);
        //Assert
        raffle.enterRaffle{value:entranceFee}();
    }
    function testStopEntranceWhileCalculating() external {
        //Arrange
        vm.prank(i_player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep();
        //Act //Assert
        vm.expectRevert(Raffle.Raffle__CalculatingPreviousWinner.selector);
        vm.prank(i_player);
        raffle.enterRaffle{value:entranceFee}();
    }
}
