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
        // Test changing the admin
        address newAdmin = getActor(1);
        vm.prank(admin);
        game.setAdmin(newAdmin);
        assertTrue(game.isAdmin(newAdmin), "New admin should be set");

        vm.startPrank(newAdmin);

        // Test adding a manager
        address newManager = getActor(2);
        game.addManager(newManager);
        assertTrue(game.isManager(newManager), "New manager should be added");

        // Test removing a manager
        game.removeManager(newManager);
        assertFalse(game.isManager(newManager), "Manager should be removed");

        // Test updating metadata
        IGame.GameMetadata memory metadata = IGame.GameMetadata(
            "New Test Game",
            "New Amazing Test Game",
            "https://newtest.com",
            "https://newtest.com/logo.png"
        );
        game.updateMetadata(metadata);

        vm.stopPrank();
    }

    function testManagerFunctionality() public {
        address manager = getActor(2);
        vm.prank(admin);
        game.addManager(manager);

        vm.startPrank(manager);

        // Test adding a player
        address player = getActor(3);
        game.addPlayer(player);
        assertTrue(game.isPlayer(player), "New player should be added");

        // Test removing a player
        game.removePlayer(player);
        assertFalse(game.isPlayer(player), "Player should be removed");

        vm.stopPrank();
    }

    function testExtensionSetting() public {
        TestExtension testExtension = new TestExtension();
        IExtension.ExtensionMetadata memory metadata = IExtension.ExtensionMetadata(
            "Test",
            "ipfs://testCid",
            address(testExtension)
        );
        IExtension.ExtensionFunction[] memory functions = new IExtension.ExtensionFunction[](1);
        functions[0] = IExtension.ExtensionFunction(testExtension.test.selector, "test()");

        IExtension.Extension memory extension = IExtension.Extension(metadata, functions);
        vm.prank(admin);
        game.addExtension(extension);

        vm.expectRevert("BaseRouter: not authorized.");
        game.addExtension(extension);
    }
}
