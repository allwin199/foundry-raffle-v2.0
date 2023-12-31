// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    /////////////////// EVENTS //////////////////
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint64 subscriptionId;
    address link;

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            callbackGasLimit,
            subscriptionId,
            link,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, PLAYER_STARTING_BALANCE);
    }

    function test_RaffleEntraceFeeIsSetCorrectly() public {
        uint256 raffleEntranceFee = raffle.getEntranceFee();
        assertEq(raffleEntranceFee, entranceFee, "Entrance Fee");
    }

    function test_RaffleStateInitializesInOpenState() public {
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assertEq(
            uint256(raffleState),
            uint256(Raffle.RaffleState.OPEN),
            "Raffle State"
        );
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                Enter Raffle
    /////////////////////////////////////////////////////////////////////////////*/

    function test_RevertsIf_NotEnoughEthSent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRaffle();
    }

    function test_RevertsIf_RaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        // Act / Assert
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_RaffleRecordsPlayerWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER, "Enter Raffle");
    }

    function test_EmitsEventOnPlayerEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectEmit({emitter: address(raffle)});
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                Check UpKeep
    /////////////////////////////////////////////////////////////////////////////*/

    modifier RaffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function test_CheckUpkeep_ReturnsFalse_IfIthasNoBalance() public {
        // Arrange
        vm.prank(PLAYER);
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assertEq(upkeepNeeded, false, "checkupkeep");
    }

    function test_CheckUpkeep_ReturnsFalse_IfRaffleIsNotOpen()
        public
        RaffleEnteredAndTimePassed
    {
        // Arrange
        raffle.performUpkeep("");
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assertEq(upkeepNeeded, false, "checkupkeep");
    }

    function test_CheckUpkeep_ReturnsFalse_IfEnoughTime_HasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assertEq(upkeepNeeded, false, "checkupkeep");
    }

    function test_checkupKeep_returnsTrue_WhenConditions_AreMet()
        public
        RaffleEnteredAndTimePassed
    {
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assertEq(upkeepNeeded, true, "checkupkeep");
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                Perform UpKeep
    /////////////////////////////////////////////////////////////////////////////*/
    function test_PerformUpkeep_revertsIf_CheckUpkeep_ReturnsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    function test_PerformUpkeep_CanOnlyRunIf_CheckUpkeepIsTrue()
        public
        RaffleEnteredAndTimePassed
    {
        // Act / Assert
        raffle.performUpkeep("");

        /// @dev if raffle.performUpkeep dosen't revert this test is considered to be pass.
    }

    function test_PerformUpkeep_EmitsRequestId()
        public
        RaffleEnteredAndTimePassed
    {
        // Act / Assert
        vm.recordLogs();
        raffle.performUpkeep(""); // this fn will emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assertGt(uint256(requestId), 0, "performupkeep");
    }

    function test_PerformUpkeep_UpdatesRaffleState()
        public
        RaffleEnteredAndTimePassed
    {
        // Act / Assert
        // raffle.performUpkeep("");
        raffle.pickWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assertEq(
            uint256(raffleState),
            uint256(Raffle.RaffleState.CALCULATING),
            "performupkeep"
        );
    }

    /*/////////////////////////////////////////////////////////////////////////////
                                FulFillRandomWords
    /////////////////////////////////////////////////////////////////////////////*/

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFuzz_FulfillRandomWords_CanOnlyBeCalled_AfterPerformUpkeep(
        uint256 _randomRequestId
    ) public RaffleEnteredAndTimePassed skipFork {
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            _randomRequestId,
            address(raffle)
        );
    }

    function test_FulfillRandomWords_PicksAWinner_ResetsAnd_SendsMoney()
        public
        RaffleEnteredAndTimePassed
        skipFork
    {
        // Arrange
        uint160 additionalEntrants = 5;
        uint160 startingIndex = 1;

        for (
            uint160 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address player = address(i);
            hoax(player, PLAYER_STARTING_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * raffle.getPlayersLength();

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // this fn will emit the requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 lastTimeStamp = raffle.getLastTimeStamp();

        // pretend to be chainlink vrf to get random number and pick winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        address recentWinner = raffle.getRecentWinner();
        uint256 playersLength = raffle.getPlayersLength();
        uint256 currentTimeStamp = raffle.getLastTimeStamp();
        uint256 recentWinnerBalance = address(recentWinner).balance;
        assertEq(
            uint256(raffleState),
            uint256(Raffle.RaffleState.OPEN),
            "fulfillrandomwords"
        );
        assertTrue(recentWinner != address(0), "fulfillrandomwords");
        assertEq(playersLength, 0, "fulfillrandomwords");
        assertGt(currentTimeStamp, lastTimeStamp, "fulfillrandomwords");
        assertEq(
            recentWinnerBalance,
            PLAYER_STARTING_BALANCE + prize - entranceFee,
            "fulfillrandomwords"
        );
    }
}
