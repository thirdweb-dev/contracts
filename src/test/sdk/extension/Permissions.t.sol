// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { Permissions, Strings } from "contracts/extension/Permissions.sol";

contract MyPermissions is Permissions {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external {
        _setRoleAdmin(role, adminRole);
    }

    function checkModifier() external view onlyRole(DEFAULT_ADMIN_ROLE) {}
}

contract ExtensionPermissions is DSTest, Test {
    MyPermissions internal ext;
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    address defaultAdmin;

    function setUp() public {
        defaultAdmin = address(0x123);

        vm.prank(defaultAdmin);
        ext = new MyPermissions();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `setRoleAdmin`
    //////////////////////////////////////////////////////////////*/

    function test_state_setRoleAdmin() public {
        bytes32 role1 = "ROLE_1";
        bytes32 role2 = "ROLE_2";

        bytes32 adminRole1 = "ADMIN_ROLE_1";
        bytes32 currentDefaultAdmin = ext.DEFAULT_ADMIN_ROLE();

        ext.setRoleAdmin(role1, adminRole1);

        assertEq(adminRole1, ext.getRoleAdmin(role1));
        assertEq(currentDefaultAdmin, ext.getRoleAdmin(role2));
    }

    function test_event_roleAdminChanged() public {
        bytes32 role1 = keccak256("ROLE_1");
        bytes32 adminRole1 = keccak256("ADMIN_ROLE_1");

        bytes32 previousAdmin = ext.getRoleAdmin(role1);

        vm.expectEmit(true, true, true, true);
        emit RoleAdminChanged(role1, previousAdmin, adminRole1);
        ext.setRoleAdmin(role1, adminRole1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `grantRole`
    //////////////////////////////////////////////////////////////*/

    function test_state_grantRole() public {
        bytes32 role1 = "ROLE_1";
        bytes32 role2 = "ROLE_2";

        bytes32 adminRole1 = "ADMIN_ROLE_1";
        address adminOne = address(0x1);

        ext.setRoleAdmin(role1, adminRole1);

        vm.prank(defaultAdmin);
        ext.grantRole(adminRole1, adminOne);

        vm.prank(adminOne);
        ext.grantRole(role1, address(0x567));

        vm.prank(defaultAdmin);
        ext.grantRole(role2, address(0x567));

        assertTrue(ext.hasRole(role1, address(0x567)));
        assertTrue(ext.hasRole(role2, address(0x567)));
    }

    function test_revert_grantRole_missingRole() public {
        address caller = address(0x345);

        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                caller,
                ext.DEFAULT_ADMIN_ROLE()
            )
        );
        ext.grantRole(keccak256("role"), address(0x1));
    }

    function test_revert_grantRole_grantToHolder() public {
        vm.startPrank(defaultAdmin);
        ext.grantRole(keccak256("role"), address(0x1));

        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsAlreadyGranted.selector, address(0x1), keccak256("role"))
        );
        ext.grantRole(keccak256("role"), address(0x1));
    }

    function test_event_grantRole() public {
        vm.startPrank(defaultAdmin);

        vm.expectEmit(true, true, true, true);
        emit RoleGranted(keccak256("role"), address(0x1), defaultAdmin);
        ext.grantRole(keccak256("role"), address(0x1));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `revokeRole`
    //////////////////////////////////////////////////////////////*/

    function test_state_revokeRole() public {
        vm.startPrank(defaultAdmin);

        ext.grantRole(keccak256("role"), address(0x567));
        assertTrue(ext.hasRole(keccak256("role"), address(0x567)));

        ext.revokeRole(keccak256("role"), address(0x567));
        assertFalse(ext.hasRole(keccak256("role"), address(0x567)));
    }

    function test_revert_revokeRole_missingRole() public {
        vm.prank(defaultAdmin);
        ext.grantRole(keccak256("role"), address(0x567));
        assertTrue(ext.hasRole(keccak256("role"), address(0x567)));

        vm.startPrank(address(0x345));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(0x345),
                ext.DEFAULT_ADMIN_ROLE()
            )
        );
        ext.revokeRole(keccak256("role"), address(0x567));
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(0x789),
                keccak256("role")
            )
        );
        ext.revokeRole(keccak256("role"), address(0x789));
        vm.stopPrank();
    }

    function test_event_revokeRole() public {
        vm.startPrank(defaultAdmin);

        ext.grantRole(keccak256("role"), address(0x1));

        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(keccak256("role"), address(0x1), defaultAdmin);
        ext.revokeRole(keccak256("role"), address(0x1));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `renounceRole`
    //////////////////////////////////////////////////////////////*/

    function test_state_renounceRole() public {
        vm.prank(defaultAdmin);
        ext.grantRole(keccak256("role"), address(0x567));
        assertTrue(ext.hasRole(keccak256("role"), address(0x567)));

        vm.prank(address(0x567));
        ext.renounceRole(keccak256("role"), address(0x567));

        assertFalse(ext.hasRole(keccak256("role"), address(0x567)));
    }

    function test_revert_renounceRole_missingRole() public {
        vm.startPrank(defaultAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, defaultAdmin, keccak256("role"))
        );
        ext.renounceRole(keccak256("role"), defaultAdmin);
        vm.stopPrank();
    }

    function test_revert_renounceRole_renounceForOthers() public {
        vm.startPrank(defaultAdmin);
        ext.grantRole(keccak256("role"), address(0x567));
        assertTrue(ext.hasRole(keccak256("role"), address(0x567)));

        vm.expectRevert(
            abi.encodeWithSelector(Permissions.PermissionsInvalidPermission.selector, defaultAdmin, address(0x567))
        );
        ext.renounceRole(keccak256("role"), address(0x567));
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `onlyRole` modifier
    //////////////////////////////////////////////////////////////*/

    function test_modifier_onlyRole() public {
        vm.startPrank(address(0x345));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(0x345),
                ext.DEFAULT_ADMIN_ROLE()
            )
        );
        ext.checkModifier();
    }
}
