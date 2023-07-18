// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import { CoreRouter } from "contracts/CoreRouter.sol";
import { PermissionsEnumerable } from "contracts/dynamic-contracts/impl/PermissionsEnumerableImpl.sol";
import "lib/dynamic-contracts/src/interface/IExtension.sol";

// Test helpers
import { BaseTest } from "./utils/BaseTest.sol";

contract CoreRouterTest is BaseTest, IExtension {
    CoreRouter internal router;

    function setUp() public override {
        super.setUp();

        vm.prank(deployer);
        router = new CoreRouter(deployer);
    }

    function test_addExtension() public {
        // Extension memory extension;
        // bytes32 role = keccak256("TRANSFER_ROLE");
        // // uint256 roleMemberCount = PermissionsEnumerable(address(router)).getRoleMemberCount(role);
        // vm.prank(deployer);
        // router.setContractURI("abc");
    }
}
