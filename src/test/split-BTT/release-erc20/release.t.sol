// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MySplit is Split {}

contract SplitTest_ReleaseERC20 is BaseTest {
    address payable public implementation;
    address payable public proxy;

    address[] public payees;
    uint256[] public shares;

    address internal caller;
    string internal _contractURI;

    MySplit internal splitContract;

    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);

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

    function test_release_zeroShares() public {
        vm.expectRevert("PaymentSplitter: account has no shares");
        splitContract.release(IERC20Upgradeable(address(erc20)), payable(address(0x123))); // arbitrary address
    }

    modifier whenNonZeroShares() {
        _;
    }

    function test_release_pendingPaymentZero() public {
        vm.expectRevert("PaymentSplitter: account is not due payment");
        splitContract.release(IERC20Upgradeable(address(erc20)), payable(payees[1]));
    }

    modifier whenPendingPaymentNonZero() {
        erc20.mint(address(splitContract), 100 ether);
        _;
    }

    function test_release() public whenPendingPaymentNonZero {
        address _payeeOne = payees[1]; // select a payee from the array
        uint256 pendingPayment = splitContract.releasable(IERC20Upgradeable(address(erc20)), _payeeOne);

        splitContract.release(IERC20Upgradeable(address(erc20)), payable(_payeeOne));

        uint256 totalReleased = splitContract.totalReleased(IERC20Upgradeable(address(erc20)));
        assertEq(splitContract.released(IERC20Upgradeable(address(erc20)), _payeeOne), pendingPayment);
        assertEq(totalReleased, pendingPayment);
        assertEq(erc20.balanceOf(_payeeOne), pendingPayment);

        // check for another payee
        address _payeeThree = payees[3];
        pendingPayment = splitContract.releasable(IERC20Upgradeable(address(erc20)), _payeeThree);

        splitContract.release(IERC20Upgradeable(address(erc20)), payable(_payeeThree));

        assertEq(splitContract.released(IERC20Upgradeable(address(erc20)), _payeeThree), pendingPayment);
        assertEq(splitContract.totalReleased(IERC20Upgradeable(address(erc20))), totalReleased + pendingPayment);
        assertEq(erc20.balanceOf(_payeeThree), pendingPayment);

        assertEq(
            erc20.balanceOf(address(splitContract)),
            100 ether - erc20.balanceOf(_payeeOne) - erc20.balanceOf(_payeeThree)
        );
    }

    function test_release_event_PaymentReleased() public whenPendingPaymentNonZero {
        address _payeeOne = payees[1]; // select a payee from the array
        uint256 pendingPayment = splitContract.releasable(IERC20Upgradeable(address(erc20)), _payeeOne);

        vm.expectEmit(true, false, false, true);
        emit ERC20PaymentReleased(IERC20Upgradeable(address(erc20)), _payeeOne, pendingPayment);
        splitContract.release(IERC20Upgradeable(address(erc20)), payable(_payeeOne));
    }
}
