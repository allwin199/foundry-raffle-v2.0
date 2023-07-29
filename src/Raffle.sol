// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2
contract Raffle {
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
    uint256 private s_lastTimestamp;

    /*/////////////////////////////////////////////////////////////////////////////
                                EVENTS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @param player emits if a player entered the raffle
    event EnteredRaffle(address indexed player);

    /*/////////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev If not enough ETH sent by user
    error Raffle__NotEnoughETHSent();

    /*/////////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Entrancefee will be in ETH
    /// @param _entranceFee Entracefee will be defined while deploying the contract
    /// @param _interval Interval will be defined while deploying the contract
    constructor(uint256 _entranceFee, uint256 _interval) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;

        /// s_lastTimestamp is set initially
        /// when the contract gets deployed, the clock will start
        s_lastTimestamp = block.timestamp;
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                External Functions
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev enterRaffle is "payable" because users have to pay to enter the lottery.
    /// @dev reverts with a custom error if `msg.value` < `entranceFee`
    /// @dev player is added to the players[] if i_entrance fee is met
    /// @dev an event will be emitted after a player is added to players[]
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /// @dev To pick a random winner
    /// 1. Get a random winner
    /// 2. Use the random number to pick a player
    /// 3. The above 2 steps should be automatically called using chainlink automation
    function pickWinner() external {
        /// @dev block.timestamp will denote the current time in seconds
        /// @dev s_lastTimestamp will denote when was the previous raffle draw
        /// @dev to pick the winner again, enough time should be passed
        /// @dev all time units are measured in seconds

        /// eg: block.timestamp = 1000; s_lastTimestamp = 500; i_interval = 600;
        /// 1000-500 = 500; 500 > 600 will be false, not enough time has passed;

        /// eg: block.timestamp = 1200; s_lastTimestamp = 500; i_interval = 600;
        /// 1200-500 = 700; 700 > 600 will be true, enough time has passed;
        /// pick winner will be called

        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                GETTER FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////*/

    /// @return Returns the actual entrace fee required to enter the raffle
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
