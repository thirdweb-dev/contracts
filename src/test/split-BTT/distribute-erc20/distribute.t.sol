// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MySplit is Split {}

contract SplitTest_DistributeERC20 is BaseTest {
    address payable public implementation;
    address payable public proxy;

    address[] public payees;
    uint256[] public shares;

    address internal caller;
    string internal _contractURI;

    MySplit internal splitContract;

    event PaymentReleased(address to, uint256 amount);

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

        erc20.mint(address(splitContract), 100 ether);
    }

    function test_distribute() public {
        uint256[] memory pendingAmounts = new uint256[](payees.length);

        // get pending payments
        for (uint256 i = 0; i < 5; i++) {
            pendingAmounts[i] = splitContract.releasable(IERC20Upgradeable(address(erc20)), payees[i]);
        }

        // distribute
        splitContract.distribute(IERC20Upgradeable(address(erc20)));

        uint256 totalPaid;
        for (uint256 i = 0; i < 5; i++) {
            totalPaid += pendingAmounts[i];

            assertEq(splitContract.released(IERC20Upgradeable(address(erc20)), payees[i]), pendingAmounts[i]);
            assertEq(erc20.balanceOf(payees[i]), pendingAmounts[i]);
        }
        assertEq(splitContract.totalReleased(IERC20Upgradeable(address(erc20))), totalPaid);

        assertEq(erc20.balanceOf(address(splitContract)), 100 ether - totalPaid);
    }
}
