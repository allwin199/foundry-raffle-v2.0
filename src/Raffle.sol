// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title A sample Raffle Contract
/// @author Prince Allwin
/// @notice This contract is for creating a sample raffle
/// @dev Implements Chainlink VRFv2
contract Raffle {
    uint256 private immutable i_entranceFee;

    /*/////////////////////////////////////////////////////////////////////////////
                                    Constructor
    /////////////////////////////////////////////////////////////////////////////*/

    /// @dev Entrancefee will be in ETH
    /// @param _entranceFee Entracefee will be defined while deploying the contract
    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    /// @dev enterRaffle is "payable" because users have to pay to enter the lottery.
    function enterRaffle() external payable {}

    // function pickWinner() {}

    /*/////////////////////////////////////////////////////////////////////////////
                                Getter Functions
    /////////////////////////////////////////////////////////////////////////////*/

    /// @return Returns the actual entrace fee required to enter the raffle
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
