// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {console} from "forge-std/Test.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;
    uint256 private immutable interval = 60;
    uint256 private lastTimeStamp;
    address s_raffleWinner;
    address private immutable vrfCoordinator;
    address[] private s_players;
    RaffleState raffleState;
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    error Raffle__InsufficientFunds();
    error Raffle__RaffleWinnerPaymentUnsuccessful();
    error Raffle__UpkeepNotNeeded();
    event PlayerEntered(address indexed player);
    event WinnerSelected(address indexed winner);
    event RequestedRaffleWinnerIndex(uint256 indexed winnerIndex);

    constructor(
        address _vrfCoordinator,
        uint256 entranceFee,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_requestConfirmations = requestConfirmations;
        i_callbackGasLimit = callbackGasLimit;
        i_numWords = numWords;
        vrfCoordinator = _vrfCoordinator;
        lastTimeStamp = block.timestamp;
        raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle__InsufficientFunds();
        }
        s_players.push(msg.sender);
        emit PlayerEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool correctTime = (block.timestamp - lastTimeStamp) > interval;
        bool RaffleOpen = raffleState == RaffleState.OPEN;
        bool contractBalance = address(this).balance > i_entranceFee;
        bool players = s_players.length > 0;
        upkeepNeeded = correctTime && RaffleOpen && contractBalance && players;
        return (upkeepNeeded, "");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }

        raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyhash,
                subId: i_subscriptionId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinnerIndex(requestId);
    }

    function fulfillRandomWords(
        /* requestId*/ uint256,
        uint256[] calldata _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address RaffleWinner = s_players[winnerIndex];
        s_raffleWinner = RaffleWinner;
        emit WinnerSelected(s_raffleWinner);
        s_players = new address[](0);
        lastTimeStamp = block.timestamp;
        raffleState = RaffleState.OPEN;
        (bool success, ) = payable(s_raffleWinner).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert Raffle__RaffleWinnerPaymentUnsuccessful();
        }
    }

    function getPlayerArray(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getWinner() external returns (address) {
        return s_raffleWinner;
    }
}
