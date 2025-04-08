// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {
    address private immutable i_user = makeAddr("USER");
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 private constant STARTING_BALANCE = 10 ether;
    bytes32 private keyHash;
    uint256 private subId;
    uint16 private requestConfirmations;
    uint32 private callbackGasLimit;
    uint32 private numWords;
    address private vrfCoordinator;
    uint256 private entranceFee;
    uint256 private interval;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        vm.deal(i_user, STARTING_BALANCE);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        keyHash = config.keyHash;
        subId = config.subId;
        requestConfirmations = config.requestConfirmations;
        callbackGasLimit = config.callbackGasLimit;
        numWords = config.numWords;
        vrfCoordinator = config.vrfCoordinator;
        entranceFee = config.entranceFee;
        interval = config.interval;
    }

    function testSufficientEntranceFee() external {
        //Arrange
        vm.prank(i_user);
        vm.expectRevert(
            Raffle.Raffle__InsufficientFundsForEntranceFee.selector
        );
        //Act
        raffle.enterRaffle();
        //Assert
    }

    function testRaffleRecordsWhenUserEntersRaffle() external {
        //arrange
        vm.prank(i_user);
        //Act
        raffle.enterRaffle{value: 1 ether}();
        //assert
        assert(raffle.getPlayer(0) == i_user);
    }

    function testEnterRaffleEmitsEvent() external {
        //Arrange
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.RaffleEntered(i_user);
        vm.prank(i_user);
        //Act
        raffle.enterRaffle{value: 1 ether}();
        //Assert
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() external {
        //Arrange

        vm.prank(i_user);
        raffle.enterRaffle{value: 1 ether}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        raffle.performUpkeep("");
        //Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(i_user);
        raffle.enterRaffle{value: 1 ether}();
    }
}
