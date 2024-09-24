// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Foundry-Lottery - A sample Raffle contract
 * @author Gaurang Bharadava
 * @notice This contract is for creating a simple Raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughETHSentToRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /* type declaration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* state variables */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    //@dev te duration of the lottery in seconds.
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        //by the function peaople can buy the lottery ticket.
        // require(msg.value >= i_entranceFee, "Not Enough ETH sent!"); //Not much Gas Efficient

        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSentToRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        // require(msg.value >= i_entranceFee, Raffle_NotEnoughETHSentToRaffle()); // Less Gas Efficient also it will wrok with via-ir pipeline.
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is a function that the chainlink node will call to see
     * if the lottery is ready to have a winner picked
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval hase passed between Raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicitly, your subscription has Link.
     * @param -ignored
     * @return upKeepNeeded - true if it's time to restart lottery.
     * @return -ignored
     */
    function checkUpKeep(
        bytes memory /* calldata */
    ) public view returns (bool upKeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upKeepNeeded, "");
    }

    //1. Get random number
    //2. Use the random number to pick player
    //3. Be automatically called
    // function pickWinner() public {
    //     //by the function a winner can be rewarder randomly.
    //     //check that enough time has passed.
    //     if ((block.timestamp - s_lastTimeStamp) < i_interval) {
    //         revert();
    //     }
    //     //Get our random number
    //     //Request RNG
    //     //Get RNG
    //     s_raffleState = RaffleState.CALCULATING;
    //     VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
    //         .RandomWordsRequest({
    //             keyHash: i_keyHash,
    //             subId: i_subscriptionId,
    //             requestConfirmations: REQUEST_CONFIRMATION,
    //             callbackGasLimit: i_callbackGasLimit,
    //             numWords: NUM_WORDS,
    //             extraArgs: VRFV2PlusClient._argsToBytes(
    //                 // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
    //                 VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
    //             )
    //         });

    //     uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    // }

    function performUpkeep(bytes calldata /* performData */) external {
        //check wether upkeep is needed
        (bool upkeepNeeded, ) = checkUpKeep("");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        //Get our random number
        //Request RNG
        //Get RNG
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* id */,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfPlayer = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfPlayer];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Function
     */

    function getEntrenceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers(
        uint256 indexOfPlayes
    ) external view returns (address payable) {
        return s_players[indexOfPlayes];
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
