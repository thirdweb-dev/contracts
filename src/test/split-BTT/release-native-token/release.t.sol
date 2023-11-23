// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MySplit is Split {}

contract SplitTest_ReleaseNativeToken is BaseTest {
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
    }

    function test_release_zeroShares() public {
        vm.expectRevert("PaymentSplitter: account has no shares");
        splitContract.release(payable(address(0x123))); // arbitrary address
    }

    modifier whenNonZeroShares() {
        _;
    }

    function test_release_pendingPaymentZero() public {
        vm.expectRevert("PaymentSplitter: account is not due payment");
        splitContract.release(payable(payees[1]));
    }

    modifier whenPendingPaymentNonZero() {
        vm.deal(address(splitContract), 100 ether);
        _;
    }

    function test_release() public whenPendingPaymentNonZero {
        address _payeeOne = payees[1]; // select a payee from the array
        uint256 pendingPayment = splitContract.releasable(_payeeOne);

        splitContract.release(payable(_payeeOne));

        uint256 totalReleased = splitContract.totalReleased();
        assertEq(splitContract.released(_payeeOne), pendingPayment);
        assertEq(totalReleased, pendingPayment);
        assertEq(_payeeOne.balance, pendingPayment);

        // check for another payee
        address _payeeThree = payees[3];
        pendingPayment = splitContract.releasable(_payeeThree);

        splitContract.release(payable(_payeeThree));

        assertEq(splitContract.released(_payeeThree), pendingPayment);
        assertEq(splitContract.totalReleased(), totalReleased + pendingPayment);
        assertEq(_payeeThree.balance, pendingPayment);

        assertEq(address(splitContract).balance, 100 ether - _payeeOne.balance - _payeeThree.balance);
    }

    function test_release_event_PaymentReleased() public whenPendingPaymentNonZero {
        address _payeeOne = payees[1]; // select a payee from the array
        uint256 pendingPayment = splitContract.releasable(_payeeOne);

        vm.expectEmit(false, false, false, true);
        emit PaymentReleased(_payeeOne, pendingPayment);
        splitContract.release(payable(_payeeOne));
    }
}
