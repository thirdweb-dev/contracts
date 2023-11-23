// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MySplit is Split {}

contract SplitTest_OtherFunctions is BaseTest {
    address payable public implementation;
    address payable public proxy;

    address[] public payees;
    uint256[] public shares;

    address internal caller;
    string internal _contractURI;

    MySplit internal splitContract;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = payable(address(new MySplit()));

        // create 5 payees and shares
        for (uint160 i = 0; i < 5; i++) {
            payees.push(getActor(i + 100));
            shares.push(i + 100);
        }

        caller = getActor(1);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = payable(
            address(
                new TWProxy(
                    implementation,
                    abi.encodeCall(Split.initialize, (deployer, CONTRACT_URI, forwarders(), payees, shares))
                )
            )
        );

        splitContract = MySplit(proxy);
        _contractURI = "ipfs://contracturi";
    }

    function test_contractType() public {
        assertEq(splitContract.contractType(), bytes32("Split"));
    }

    function test_contractVersion() public {
        assertEq(splitContract.contractVersion(), uint8(1));
    }
}
