// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { PermissionsEnumerable, Strings } from "contracts/extension/PermissionsEnumerable.sol";

contract MyPermissionsEnumerable is PermissionsEnumerable {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

contract ExtensionPermissionsEnumerable is DSTest, Test {
    MyPermissionsEnumerable internal ext;

    address defaultAdmin;

    function setUp() public {
        defaultAdmin = address(0x123);

        vm.prank(defaultAdmin);
        ext = new MyPermissionsEnumerable();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `grantRole`
    //////////////////////////////////////////////////////////////*/

    function test_state_grantRole() public {
        bytes32 role1 = keccak256("ROLE_1");

        address[] memory members = new address[](3);

        members[0] = address(0);
        members[1] = address(1);
        members[2] = address(2);

        vm.startPrank(defaultAdmin);

        ext.grantRole(role1, members[0]);
        assertEq(1, ext.getRoleMemberCount(role1));

        ext.grantRole(role1, members[1]);
        assertEq(2, ext.getRoleMemberCount(role1));

        ext.grantRole(role1, members[2]);
        assertEq(3, ext.getRoleMemberCount(role1));

        for (uint256 i = 0; i < members.length; i++) {
            assertEq(members[i], ext.getRoleMember(role1, i));
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `revokeRole`
    //////////////////////////////////////////////////////////////*/

    function test_state_revokeRole() public {
        bytes32 role1 = keccak256("ROLE_1");

        address[] memory members = new address[](3);

        members[0] = address(0);
        members[1] = address(1);
        members[2] = address(2);

        vm.startPrank(defaultAdmin);

        ext.grantRole(role1, members[0]);
        assertEq(1, ext.getRoleMemberCount(role1));

        ext.grantRole(role1, members[1]);
        assertEq(2, ext.getRoleMemberCount(role1));

        ext.grantRole(role1, members[2]);
        assertEq(3, ext.getRoleMemberCount(role1));

        for (uint256 i = 0; i < members.length; i++) {
            assertEq(members[i], ext.getRoleMember(role1, i));
        }

        // revoke roles, and check updated list of members
        ext.revokeRole(role1, members[1]);
        assertEq(2, ext.getRoleMemberCount(role1));
        assertEq(members[2], ext.getRoleMember(role1, 1));

        ext.revokeRole(role1, members[0]);
        assertEq(1, ext.getRoleMemberCount(role1));
        assertEq(members[2], ext.getRoleMember(role1, 0));

        // re-grant roles, and check updated list of members
        ext.grantRole(role1, members[0]);
        assertEq(2, ext.getRoleMemberCount(role1));
        assertEq(members[2], ext.getRoleMember(role1, 0));
        assertEq(members[0], ext.getRoleMember(role1, 1));

        ext.grantRole(role1, members[1]);
        assertEq(3, ext.getRoleMemberCount(role1));
        assertEq(members[2], ext.getRoleMember(role1, 0));
        assertEq(members[0], ext.getRoleMember(role1, 1));
        assertEq(members[1], ext.getRoleMember(role1, 2));
    }
}
