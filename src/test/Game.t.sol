// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.sol";
import "lib/dynamic-contracts/src/interface/IExtension.sol";
import "contracts/prebuilts/game/core/Game.sol";
import "contracts/prebuilts/game/player/Player.sol";
import "contracts/prebuilts/game/achievement/Achievement.sol";
import "contracts/prebuilts/game/leaderboard/Leaderboard.sol";
import "contracts/prebuilts/game/reward/Reward.sol";
import "forge-std/console.sol";
import { IRulesEngine } from "contracts/extension/interface/IRulesEngine.sol";

contract TestExtension {
    uint256 private _test;

    function test() external {
        _test += 1;
    }
}

contract GameTest is BaseTest {
    Game public game;
    Player public player;
    Leaderboard public leaderboard;
    Reward public reward;
    Achievement public achievement;
    address public admin;

    function setUp() public override {
        super.setUp();
        admin = getActor(0);
        game = new Game(
            admin,
            IGame.GameMetadata("Test Game", "Amazing Test Game", "https://test.com", "https://test.com/logo.png")
        );
        player = new Player();
        leaderboard = new Leaderboard();
        reward = new Reward();
        achievement = new Achievement();

        vm.startPrank(admin);

        // IPlayer
        console.log("Setting up Player extension");

        IExtension.ExtensionFunction[] memory playerFunctions = new IExtension.ExtensionFunction[](5);
        playerFunctions[0] = IExtension.ExtensionFunction(
            player.createPlayer.selector,
            "createPlayer(address,(string,string,uint256,bytes))"
        );
        playerFunctions[1] = IExtension.ExtensionFunction(
            player.updatePlayerInfo.selector,
            "updatePlayerInfo(address,(string,string,uint256,bytes))"
        );
        playerFunctions[2] = IExtension.ExtensionFunction(
            player.createPlayerWithSignature.selector,
            "createPlayerWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        playerFunctions[3] = IExtension.ExtensionFunction(
            player.updatePlayerInfoWithSignature.selector,
            "updatePlayerInfoWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        playerFunctions[4] = IExtension.ExtensionFunction(player.getPlayerInfo.selector, "getPlayerInfo(address)");

        game.addExtension(
            IExtension.Extension(
                IExtension.ExtensionMetadata("Player", "ipfs://playerCid", address(player)),
                playerFunctions
            )
        );

        // ILeaderboard
        console.log("Setting up Leaderboard extension");
        IExtension.ExtensionFunction[] memory leaderboardFunctions = new IExtension.ExtensionFunction[](15);
        leaderboardFunctions[0] = IExtension.ExtensionFunction(
            leaderboard.createLeaderboard.selector,
            "createLeaderboard((string,bytes32[],address[]))"
        );
        leaderboardFunctions[1] = IExtension.ExtensionFunction(
            leaderboard.updateLeaderboardInfo.selector,
            "updateLeaderboardInfo(uint256,(string,bytes32[],address[]))"
        );
        leaderboardFunctions[2] = IExtension.ExtensionFunction(
            leaderboard.addPlayerToLeaderboard.selector,
            "addPlayerToLeaderboard(uint256,address)"
        );
        leaderboardFunctions[3] = IExtension.ExtensionFunction(
            leaderboard.removePlayerFromLeaderboard.selector,
            "removePlayerFromLeaderboard(uint256,address)"
        );
        leaderboardFunctions[4] = IExtension.ExtensionFunction(
            leaderboard.createLeaderboardWithSignature.selector,
            "createLeaderboardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        leaderboardFunctions[5] = IExtension.ExtensionFunction(
            leaderboard.updateLeaderboardInfoWithSignature.selector,
            "updateLeaderboardInfoWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        leaderboardFunctions[6] = IExtension.ExtensionFunction(
            leaderboard.addPlayerToLeaderboardWithSignature.selector,
            "addPlayerToLeaderboardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        leaderboardFunctions[7] = IExtension.ExtensionFunction(
            leaderboard.removePlayerFromLeaderboardWithSignature.selector,
            "removePlayerFromLeaderboardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        leaderboardFunctions[8] = IExtension.ExtensionFunction(
            leaderboard.getLeaderboardCount.selector,
            "getLeaderboardCount()"
        );
        leaderboardFunctions[9] = IExtension.ExtensionFunction(
            leaderboard.getLeaderboardInfo.selector,
            "getLeaderboardInfo(uint256)"
        );
        leaderboardFunctions[10] = IExtension.ExtensionFunction(
            leaderboard.getPlayerScore.selector,
            "getPlayerScore(uint256,address)"
        );
        leaderboardFunctions[11] = IExtension.ExtensionFunction(
            leaderboard.getPlayerRank.selector,
            "getPlayerRank(uint256,address)"
        );
        leaderboardFunctions[12] = IExtension.ExtensionFunction(
            leaderboard.getLeaderboardScores.selector,
            "getLeaderboardScores(uint256,uint8)"
        );
        leaderboardFunctions[13] = IExtension.ExtensionFunction(
            leaderboard.getLeaderboardScoresInRange.selector,
            "getLeaderboardScoresInRange(uint256,uint256,uint256,uint8)"
        );
        leaderboardFunctions[14] = IExtension.ExtensionFunction(
            leaderboard.createRuleMultiplicative.selector,
            "createRuleMultiplicative((address,uint8,uint256,uint256))"
        );
        game.addExtension(
            IExtension.Extension(
                IExtension.ExtensionMetadata("Leaderboard", "ipfs://leaderboardCid", address(leaderboard)),
                leaderboardFunctions
            )
        );

        // IReward
        console.log("Setting up Reward extension");
        IExtension.ExtensionFunction[] memory rewardFunctions = new IExtension.ExtensionFunction[](7);
        rewardFunctions[0] = IExtension.ExtensionFunction(
            reward.registerReward.selector,
            "registerReward(string,(address,uint8,uint256,uint256))"
        );
        rewardFunctions[1] = IExtension.ExtensionFunction(reward.unregisterReward.selector, "unregisterReward(string)");
        rewardFunctions[2] = IExtension.ExtensionFunction(reward.claimReward.selector, "claimReward(address,string)");
        rewardFunctions[3] = IExtension.ExtensionFunction(
            reward.registerRewardWithSignature.selector,
            "registerRewardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        rewardFunctions[4] = IExtension.ExtensionFunction(
            reward.unregisterRewardWithSignature.selector,
            "unregisterRewardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        rewardFunctions[5] = IExtension.ExtensionFunction(
            reward.claimRewardWithSignature.selector,
            "claimRewardWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        rewardFunctions[6] = IExtension.ExtensionFunction(reward.getRewardInfo.selector, "getRewardInfo(string)");
        game.addExtension(
            IExtension.Extension(
                IExtension.ExtensionMetadata("Reward", "ipfs://rewardCid", address(reward)),
                rewardFunctions
            )
        );

        // IAchievement
        console.log("Setting up Achievement extension");
        IExtension.ExtensionFunction[] memory achievementFunctions = new IExtension.ExtensionFunction[](10);
        achievementFunctions[0] = IExtension.ExtensionFunction(
            achievement.createAchievement.selector,
            "createAchievement(string,(bool,bool,string))"
        );
        achievementFunctions[1] = IExtension.ExtensionFunction(
            achievement.updateAchievement.selector,
            "updateAchievement(string,(bool,bool,string))"
        );
        achievementFunctions[2] = IExtension.ExtensionFunction(
            achievement.deleteAchievement.selector,
            "deleteAchievement(string)"
        );
        achievementFunctions[3] = IExtension.ExtensionFunction(
            achievement.claimAchievement.selector,
            "claimAchievement(address,string)"
        );
        achievementFunctions[4] = IExtension.ExtensionFunction(
            achievement.createAchievementWithSignature.selector,
            "createAchievementWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        achievementFunctions[5] = IExtension.ExtensionFunction(
            achievement.updateAchievementWithSignature.selector,
            "updateAchievementWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        achievementFunctions[6] = IExtension.ExtensionFunction(
            achievement.deleteAchievementWithSignature.selector,
            "deleteAchievementWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        achievementFunctions[7] = IExtension.ExtensionFunction(
            achievement.claimAchievementWithSignature.selector,
            "claimAchievementWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        achievementFunctions[8] = IExtension.ExtensionFunction(
            achievement.getAchievementInfo.selector,
            "getAchievementInfo(string)"
        );
        achievementFunctions[9] = IExtension.ExtensionFunction(
            achievement.getAchievementClaimCount.selector,
            "getAchievementClaimCount(address,string)"
        );
        game.addExtension(
            IExtension.Extension(
                IExtension.ExtensionMetadata("Achievement", "ipfs://achievementCid", address(achievement)),
                achievementFunctions
            )
        );

        vm.stopPrank();
    }

    /// GENERAL TESTS ///

    function testOptimistic() public {
        vm.startPrank(admin);

        // Player tests
        console.log("Testing Player extension");

        console.log("[Player] Adding players");
        IPlayer playerExtension = IPlayer(address(game));
        IPlayer.PlayerInfo memory player1Info = IPlayer.PlayerInfo("Player 1", "ipfs://avatar1", 1, "");
        IPlayer.PlayerInfo memory player2Info = IPlayer.PlayerInfo("Player 2", "ipfs://avatar2", 2, "");
        address player1 = getActor(1);
        address player2 = getActor(2);
        playerExtension.createPlayer(player1, player1Info);
        playerExtension.createPlayer(player2, player2Info);

        console.log("[Player] Checking player info");
        assertEq(playerExtension.getPlayerInfo(player1).name, "Player 1");
        assertEq(playerExtension.getPlayerInfo(player2).avatar, "ipfs://avatar2");

        console.log("[Player] Checking update info");
        playerExtension.updatePlayerInfo(player1, player2Info);
        assertEq(playerExtension.getPlayerInfo(player1).avatar, "ipfs://avatar2");

        console.log("[Player] Checking update info (1)");
        playerExtension.updatePlayerInfo(player1, player1Info);
        assertEq(playerExtension.getPlayerInfo(player1).avatar, "ipfs://avatar1");

        // Leaderboard tests
        console.log("Testing Leaderboard extension");

        console.log("[Leaderboard] Adding rules");
        IRulesEngine leaderboardRulesEngine = IRulesEngine(address(game));
        bytes32 ruleId = leaderboardRulesEngine.createRuleMultiplicative(
            IRulesEngine.RuleTypeMultiplicative(address(erc20), IRulesEngine.TokenType.ERC20, 0, 1)
        );

        console.log("[Leaderboard] Minting tokens to players");
        erc20.mint(player1, 1 * 1e18);
        erc20.mint(player2, 2 * 1e18);

        console.log("[Leaderboard] Creating leaderboard");
        ILeaderboard leaderboardExtension = ILeaderboard(address(game));
        ILeaderboard.LeaderboardInfo memory leaderboardInfo = ILeaderboard.LeaderboardInfo(
            "Leaderboard 1",
            new bytes32[](1),
            new address[](0)
        );
        leaderboardInfo.rules[0] = ruleId;
        leaderboardExtension.createLeaderboard(leaderboardInfo);

        console.log("[Leaderboard] Checking count and info");
        assertEq(leaderboardExtension.getLeaderboardCount(), 1);
        assertEq(leaderboardExtension.getLeaderboardInfo(0).name, "Leaderboard 1");

        console.log("[Leaderboard] Checking update info");
        leaderboardExtension.updateLeaderboardInfo(0, leaderboardInfo);
        assertEq(leaderboardExtension.getLeaderboardInfo(0).name, "Leaderboard 1");

        console.log("[Leaderboard] Adding players");
        leaderboardExtension.addPlayerToLeaderboard(0, player1);
        leaderboardExtension.addPlayerToLeaderboard(0, player2);

        console.log("[Leaderboard] Checking player scores");
        assertEq(leaderboardExtension.getPlayerScore(0, player1), 1);
        assertEq(leaderboardExtension.getPlayerScore(0, player2), 2);

        console.log("[Leaderboard] Checking player ranks");
        assertEq(leaderboardExtension.getPlayerRank(0, player1), 2);
        assertEq(leaderboardExtension.getPlayerRank(0, player2), 1);

        console.log("[Leaderboard] Removing player2");
        leaderboardExtension.removePlayerFromLeaderboard(0, player2);
        assertEq(leaderboardExtension.getPlayerScore(0, player2), 0);
        assertEq(leaderboardExtension.getPlayerRank(0, player2), type(uint256).max);
        assertEq(leaderboardExtension.getPlayerRank(0, player1), 1);

        // Reward tests
        console.log("Testing Reward extension");

        console.log("[Reward] Registering reward");
        address randomPlayer = getActor(1234554321);
        IReward rewardExtension = IReward(address(game));
        IReward.RewardInfo memory rewardInfo = IReward.RewardInfo(
            address(erc20),
            IReward.RewardType.ERC20,
            0,
            1 * 1e18
        );
        erc20.mint(address(game), 100 * 1e18);
        rewardExtension.registerReward("Reward 1", rewardInfo);
        assertEq(rewardExtension.getRewardInfo("Reward 1").rewardAddress, address(erc20));

        console.log("[Reward] Claiming reward");
        rewardExtension.claimReward(randomPlayer, "Reward 1");
        assertEq(erc20.balanceOf(randomPlayer), 1 * 1e18);

        console.log("[Reward] Unregistering reward");
        rewardExtension.unregisterReward("Reward 1");
        assertEq(rewardExtension.getRewardInfo("Reward 1").rewardAddress, address(0));

        // Achievement tests

        console.log("Testing Achievement extension");
        rewardExtension.registerReward("Reward 1", rewardInfo);
        IAchievement achievementExtension = IAchievement(address(game));
        IAchievement.AchievementInfo memory achievementInfo = IAchievement.AchievementInfo(true, false, "Reward 1");
        achievementExtension.createAchievement("Achievement 1", achievementInfo);

        console.log("[Achievement] Claiming achievement");
        achievementExtension.claimAchievement(randomPlayer, "Achievement 1");
        assertEq(erc20.balanceOf(randomPlayer), 2 * 1e18);

        vm.stopPrank();
    }

    /// GAME TESTS ///

    function testGameMetadata() public {
        // Test the game's metadata retrieval
        IGame.GameMetadata memory metadata = game.getMetadata();
        assertEq(metadata.name, "Test Game");
        assertEq(metadata.description, "Amazing Test Game");
        assertEq(metadata.website, "https://test.com");
        assertEq(metadata.logo, "https://test.com/logo.png");
    }

    function testAdminFunctionality() public {
        address randomAddress = getActor(69);

        // Test setting a new admin
        address newAdmin = getActor(1);
        vm.prank(admin);
        game.setAdmin(newAdmin);
        assertTrue(game.isAdmin(newAdmin), "New admin should be set");

        // Test setting the same admin again (should fail)
        vm.prank(newAdmin);
        vm.expectRevert("GameRouter: AlreadyAdmin.");
        game.setAdmin(newAdmin);

        // Test setting an admin as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not admin.");
        game.setAdmin(randomAddress);

        // Test adding a manager
        address newManager = getActor(2);
        vm.prank(newAdmin);
        game.addManager(newManager);
        assertTrue(game.isManager(newManager), "New manager should be added");

        // Test adding the same manager (should fail)
        vm.prank(newAdmin);
        vm.expectRevert("GameRouter: Manager already exists.");
        game.addManager(newManager);

        // Test adding a manager as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not admin.");
        game.addManager(randomAddress);

        // Test removing a manager
        vm.prank(newAdmin);
        game.removeManager(newManager);
        assertFalse(game.isManager(newManager), "Manager should be removed");

        // Test removing a non-existing manager (should fail)
        vm.prank(newAdmin);
        vm.expectRevert("GameRouter: Manager does not exist.");
        game.removeManager(newManager);

        // Test removing a manager as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not admin.");
        game.removeManager(randomAddress);

        // Test updating metadata
        IGame.GameMetadata memory metadata = IGame.GameMetadata(
            "New Test Game",
            "New Amazing Test Game",
            "https://newtest.com",
            "https://newtest.com/logo.png"
        );
        vm.prank(newAdmin);
        game.updateMetadata(metadata);

        // Test updating metadata as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not admin.");
        game.updateMetadata(metadata);
    }

    function testManagerFunctionality() public {
        address randomAddress = getActor(69);

        address manager = getActor(2);
        vm.prank(admin);
        game.addManager(manager);

        // Test adding a player
        address player = getActor(3);
        vm.prank(manager);
        game.addPlayer(player);
        assertTrue(game.isPlayer(player), "New player should be added");

        // Test adding the same player again (should fail)
        vm.expectRevert("GameRouter: Player already exists.");
        vm.prank(manager);
        game.addPlayer(player);

        // Test adding a player as a non-manager (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not manager.");
        game.addPlayer(randomAddress);

        // Test removing a player
        vm.prank(manager);
        game.removePlayer(player);
        assertFalse(game.isPlayer(player), "Player should be removed");

        // Test removing a non-existing player (should fail)
        vm.expectRevert("GameRouter: Player does not exist.");
        vm.prank(manager);
        game.removePlayer(player);

        // Test removing a player as a non-manager (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("GameLibrary: Not manager.");
        game.removePlayer(randomAddress);
    }

    function testExtensionSetting() public {
        address randomAddress = getActor(69);

        // Test extension
        TestExtension testExtension = new TestExtension();
        IExtension.ExtensionMetadata memory metadata = IExtension.ExtensionMetadata(
            "Test",
            "ipfs://testCid",
            address(testExtension)
        );
        IExtension.ExtensionFunction[] memory functions = new IExtension.ExtensionFunction[](1);
        functions[0] = IExtension.ExtensionFunction(testExtension.test.selector, "test()");
        IExtension.Extension memory extension = IExtension.Extension(metadata, functions);

        // Test adding an extension as admin
        vm.prank(admin);
        game.addExtension(extension);

        // Test adding the same extension again (should fail)
        vm.prank(admin);
        vm.expectRevert("ExtensionManager: extension already exists.");
        game.addExtension(extension);

        // Test adding an extension as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("ExtensionManager: unauthorized.");
        game.addExtension(extension);

        // Test removing an extension as admin
        vm.prank(admin);
        game.removeExtension(extension.metadata.name);

        // Test removing a non-existing extension (should fail)
        vm.prank(admin);
        vm.expectRevert("ExtensionManager: extension does not exist.");
        game.removeExtension(extension.metadata.name);

        // Test removing an extension as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("ExtensionManager: unauthorized.");
        game.removeExtension(extension.metadata.name);
    }
}
