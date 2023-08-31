// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IExtension.sol";
import "contracts/prebuilts/game/core/Game.sol";
import "./utils/BaseTest.sol";

contract TestExtension {
    uint256 private _test;

    function test() external {
        _test += 1;
    }
}

contract GameTest is BaseTest {
    Game public game;
    address public admin;

    function setUp() public override {
        super.setUp();
        admin = getActor(0);
        game = new Game(
            admin,
            IGame.GameMetadata("Test Game", "Amazing Test Game", "https://test.com", "https://test.com/logo.png")
        );
    }

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
        vm.expectRevert("ExtensionState: extension already exists.");
        game.addExtension(extension);

        // Test adding an extension as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("BaseRouter: not authorized.");
        game.addExtension(extension);

        // Test removing an extension as admin
        vm.prank(admin);
        game.removeExtension(extension);

        // Test removing a non-existing extension (should fail)
        vm.prank(admin);
        vm.expectRevert("ExtensionState: extension does not exist.");
        game.removeExtension(extension);

        // Test removing an extension as a non-admin (should fail)
        vm.prank(randomAddress);
        vm.expectRevert("BaseRouter: not authorized.");
        game.removeExtension(extension);
    }
}
