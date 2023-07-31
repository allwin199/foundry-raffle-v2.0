// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2
contract Raffle is VRFConsumerBaseV2 {
    /*/////////////////////////////////////////////////////////////////////////////
                                TYPE DECLARATIONS
    /////////////////////////////////////////////////////////////////////////////*/

    ////////////////////// ENUM ////////////////////
    /// @dev OPEN --> 0 | CALCULATING -> 1
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                PRIVATE STORAGE
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev i_entracefee will be set in the constructor
    uint256 private immutable i_entranceFee;

    /// @dev i_interval will determine the interval between each raffle draws
    /// @dev i_interval will be set in the constructor
    uint256 private immutable i_interval;

    /// @dev players[] keeps track of all the players
    /// @dev players[] is payable because we have to pay them if they win.
    address payable[] private s_players;

    /// @dev stores the last time when the raffle was drawn.
    uint256 private s_lastTimeStamp;

    /// @dev keeps track of the recent winner
    address private s_recentWinner;

    /// @dev keeps track of the raffle state
    RaffleState private s_raffleState;

    ////////////////////// VRF ////////////////////

    /// @dev vrfCoordinator address will change chain to chain
    /// @dev vrfCoordinator address will be set during the deployment
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    /// @dev The gas lane to use, which specifies the maximum gas price to bump to.
    /// @dev gas lane will be set during the deployment
    bytes32 private immutable i_gasLane;

    /// @dev Your subscription ID.
    /// @dev SubscriptionId will be set during the deployment
    uint64 private immutable i_subscriptionId;

    /// @dev This limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    /// @dev CallbackGasLimit will be set during the deployment
    uint32 private immutable i_callbackGasLimit;

    /// @dev No of block confirmations required
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /// @dev We require only 1 random number per request
    uint32 private constant NUM_WORDS = 1;

    /*/////////////////////////////////////////////////////////////////////////////
                                EVENTS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @param player emits if a player entered the raffle
    event EnteredRaffle(address indexed player);

    /// @param winner emits if a winner is picked
    event PickedWinner(address indexed winner);

    event RequestedRaffleWinner(uint256 indexed requestId);

    /*/////////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev If not enough ETH sent by user
    error Raffle__NotEnoughETHSent();

    /// @dev If the transaction failed while sending back money to the player
    error Raffle_TransferFailed();

    /// @dev If the raffle state is not OPEN
    error Raffle__NotOpen();

    /// @dev If the upkeepIsNotNeeded
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /*/////////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Entrancefee will be in ETH
    /// @param _entranceFee Entracefee will be defined while deploying the contract
    /// @param _interval Interval will be defined while deploying the contract
    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint32 _callbackGasLimit,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;

        /// @dev s_lastTimeStamp is set initially
        /// @dev when the contract gets deployed, the clock will start
        s_lastTimeStamp = block.timestamp;

        /// @dev raffle state is set default as OPEN
        s_raffleState = RaffleState.OPEN;

        /////////////// VRF ///////////////////
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_callbackGasLimit = _callbackGasLimit;
        i_subscriptionId = _subscriptionId;
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                External Functions
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev follows CHECK, EFFECTS, INTERACTIONS
    /// @dev enterRaffle is "payable" because users have to pay to enter the lottery.
    /// @dev reverts with a custom error if `msg.value` < `entranceFee`
    /// @dev reverts with a custom error if raffle state is not OPEN
    /// @dev player is added to the players[] if i_entrance fee is met
    /// @dev an event will be emitted after a player is added to players[]
    function enterRaffle() external payable {
        /// @dev CHECKS
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        /// @dev EFFECTS
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /// @dev This is the function that Chainlink Automation nodes call to see if it's time to perform an upkeep.
    /// @dev The following should be true for checkupkeep to return true
    /// 1. The time interval has passed between raffle REQUEST_CONFIRMATIONS
    /// 2. The raffle is in OPEN state
    /// 3. The contract has ETH (aka, players)
    /// 4. The subscription is funded with link(Implicit Check)
    /// @dev once the checkupkeep returns true, performupkeep will be called by chainlink nodes
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        /// @dev block.timestamp will denote the current time in seconds
        /// @dev s_lastTimeStamp will denote when was the previous raffle draw
        /// @dev to pick the winner again, enough time should be passed
        /// @dev all time units are measured in seconds

        /// eg: block.timestamp = 1000; s_lastTimeStamp = 500; i_interval = 600;
        /// 1000-500 = 500; 500 > 600 will be false, not enough time has passed;

        /// eg: block.timestamp = 1200; s_lastTimeStamp = 500; i_interval = 600;
        /// 1200-500 = 700; 700 > 600 will be true, enough time has passed;
        /// pick winner will be called

        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        /// @dev since in returns we have bool upkeepNeeded
        /// it is not required to say
        /// return(upkeepneeded, "0x0")
        /// (0x0) refers to blank bytes object
        /// but her we are explicitly returning

        return (upkeepNeeded, "0x0");
    }

    /// @dev this fn will call the chainlink vrf to generate random number and pick a winner
    /// @dev since this fn is external anyone can call this at any time, we don't want that.
    /// This should be called only by chainlink nodes when checkupkeep is true
    /// so lets add the checkupkeep
    function performUpkeep(bytes calldata /* performData */) external {
        /// @dev It is highly recommend revalidating the upkeep in the performUpkeep function
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
            /// @dev since s_raffleState is in enum Rafflestate, we have to typecast
        }

        ///@dev once the upkeepNeeded is true, It will call the pickwinner()
        pickWinner();
    }

    /// @dev follows CHECK, EFFECTS, INTERACTIONS
    /// @dev To pick a random winner
    /// 1. Get a random winner
    /// 2. Use the random number to pick a player
    /// 3. The above 2 steps should be automatically called using chainlink automation
    function pickWinner() public {
        /// @dev EFFECTS

        /// @dev Raffle state is set to calculating before calling the chainlink vrf
        s_raffleState = RaffleState.CALCULATING;

        /// @dev INTERACTIONS

        /// @dev Chainlink vrf is a 2 transaction process.
        /// 1. Request the Random Number
        /// 2. Get the random number
        /// we will request the random number
        /// callback fn from chainlink vrf will call the fn to picking the actual winner.

        /// @dev vrfCoordinator contract will contain a fn called "requestRandomWords"
        /// @dev Will revert if subscription is not set and funded.
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    /// @dev follows CHECK, EFFECTS, INTERACTIONS
    /// this fn will be called by chainlink vrf to return random number
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        /// @dev EFFECTS

        /// @dev _randomWords will return an array, since we requested only one random number, it will have only one
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        /// @dev let's say _randomWords[0] = 122214 and s_players.length = 3
        /// @dev since the players length is 3
        /// @dev picked winner will come under the index of players eg: 0,1,2
        /// @dev 122214 % 3 = 0 --> 0th index will be the winner
        address payable pickedWinner = s_players[indexOfWinner];
        s_recentWinner = pickedWinner;

        /// @dev reset the players array after winner is picked
        s_players = new address payable[](0);

        /// @dev reset the last time stamp after winner is picked
        s_lastTimeStamp = block.timestamp;

        /// @dev raffle state is set as OPEN, after the winner is picked
        s_raffleState = RaffleState.OPEN;

        emit PickedWinner(pickedWinner);

        /// @dev INTERACTIONS
        /// @dev reverts with custom error if the transaction fails
        (bool success, ) = pickedWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                GETTER FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @return Returns the actual entrace fee required to enter the raffle
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
