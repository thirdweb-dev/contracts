// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/ThrowawaySplit.sol";

import "../utils/BaseTest.sol";

contract ThrowawaySplitTest is BaseTest {
    address admin;

    ThrowawaySplit split;

    IThrowawaySplit.Deployer[] internal deployers;

    function setUp() public override {
        super.setUp();

        admin = getActor(5000);
        vm.deal(admin, 100 ether);

        deployers.push(IThrowawaySplit.Deployer({ deployer: getActor(91), value: 1 ether }));
        deployers.push(IThrowawaySplit.Deployer({ deployer: getActor(92), value: 2 ether }));
        deployers.push(IThrowawaySplit.Deployer({ deployer: getActor(93), value: 3 ether }));
    }

    function test_deployerBalance() public {
        for (uint256 i = 0; i < deployers.length; i++) {
            assertEq(deployers[i].deployer.balance, 0);
        }

        vm.prank(admin);
        split = new ThrowawaySplit{ value: 6 ether }(deployers);

        for (uint256 i = 0; i < deployers.length; i++) {
            assertEq(deployers[i].deployer.balance, deployers[i].value);
        }
    }
}
