// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// Pragma statements

// Import statements

// Events

// Errors

// Interfaces

// Libraries

// Contracts

// Inside each contract, library or interface, use the following order:

// Type declarations

// State variables

// Events

// Errors

// Modifiers

// Functions
/**
 * @title A sample Raffle contract
 * @author Zion Livingstone
 * @notice Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Type declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    // State variables
    address payable[] private s_players;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; //@dev duration of the lottery in seconds
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_gasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    // Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    // Errors
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__WinnnerPaymentUnsuccessfull();
    error Raffle__CalculatingPreviousWinner();
    error Raffle__upkeepisFalse(uint256 balance,uint256 playersLength,uint256 rafflestate);

    // Constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint32 gaslimit,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gaslane;
        i_gasLimit = gaslimit;
        i_subscriptionId=subscriptionId;
        s_raffleState = RaffleState.OPEN;
    }

    // Modifiers

    // Functions

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingPreviousWinner();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }
    /**
     * @dev this is the function that the chainlink nodes will call to see if the lottery is ready to have a winner picked
     * the following needs to be true:
     * the lottery is open 
     * the contract has eth
     * the time interval has passed between raffle runs
     * implicitly the subscription has link
     * @param - ignored
     * @return upKeepNeeded -if its time to initiate lottery
     * @return 
     */
    function checkUpkeep(bytes memory /*checkdata*/)  public view returns(bool upKeepNeeded, bytes memory /*performData*/){
        bool timeHasPassed=((block.timestamp - s_lastTimeStamp >= i_interval));
        bool isOpen= s_raffleState==RaffleState.OPEN;
        bool hasBalance=(address(this).balance)>0;
        bool hasPlayers= s_players.length>0;
        upKeepNeeded=timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upKeepNeeded,"0x0");
    }
    function performUpkeep() external {
        //checks
        (bool upKeepNeeded,)=checkUpkeep("");
            if (!upKeepNeeded) {
                revert Raffle__upkeepisFalse(address(this).balance,s_players.length,uint256(s_raffleState));
            }
        //Effects
        s_raffleState = RaffleState.CALCULATING;


        //interactions
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_gasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

       uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        //checks

        //effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp=block.timestamp;
        emit WinnerPicked(s_recentWinner);

        //interactions
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__WinnnerPaymentUnsuccessfull();
        }
    }
    function getRaffleState() external view  returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }
}
