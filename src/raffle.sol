// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subId;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;

    address private vrfCoordinator;
    uint256 private s_lastTimeStamp;
    address[] private s_players;
    RaffleState public raffleState;
    error Raffle__InsufficientFundsForEntranceFee();
    error Raffle__UpKeepNeededIsNotTrue();
    error Raffle__WinnerPaymentUnsuccesful();
    error Raffle__RaffleNotOpen();
    event RaffleEntered(address indexed player);
    event WinnerSelected(address indexed player);
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    constructor(
        bytes32 keyHash,
        uint256 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address s_vrfCoordinator,
        uint256 entranceFee,
        uint256 interval
    ) VRFConsumerBaseV2Plus(s_vrfCoordinator) {
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_subId = subId;
        i_requestConfirmations = requestConfirmations;
        i_callbackGasLimit = callbackGasLimit;
        i_numWords = numWords;
        vrfCoordinator = s_vrfCoordinator;
        i_entranceFee = entranceFee;
        i_interval=interval;
        raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__InsufficientFundsForEntranceFee();
        }
        if (raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        emit RaffleEntered(msg.sender);
        s_players.push(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeInterval = block.timestamp - s_lastTimeStamp >=i_interval;
        bool balance = address(this).balance >= i_entranceFee;
        bool RaffleOpen = raffleState == RaffleState.OPEN;
        bool player = s_players.length > 0;
        upkeepNeeded = timeInterval && balance && RaffleOpen && player;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNeededIsNotTrue();
        }
        raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subId,
                requestConfirmations: i_requestConfirmations,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address winner = s_players[winnerIndex];
        s_players = new address[](0);
        emit WinnerSelected(winner);
        raffleState = RaffleState.OPEN;
        (bool success, ) = payable(winner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__WinnerPaymentUnsuccesful();
        }
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function setRaffleState() external {
        raffleState = RaffleState.CALCULATING;
    }
}
