// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AirdropERC20, IAirdropERC20 } from "contracts/airdrop/AirdropERC20.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC20Test is BaseTest {
    AirdropERC20 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC20.AirdropContent[] internal _contentsOne;
    IAirdropERC20.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC20(getContract("AirdropERC20"));

        tokenOwner = getWallet();

        erc20.mint(address(tokenOwner), 10_000 ether);
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), type(uint256).max);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(
                IAirdropERC20.AirdropContent({
                    tokenAddress: address(erc20),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    amount: 10 ether
                })
            );
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(
                IAirdropERC20.AirdropContent({
                    tokenAddress: address(erc20),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    amount: 10 ether
                })
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `processPayments`
    //////////////////////////////////////////////////////////////*/

    function test_state_processPayments_full() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
    }

    function test_state_processPayments_partial() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 3000 ether);
    }

    function test_state_processPayments_nativeToken_full() public {
        vm.deal(deployer, 10_000 ether);

        uint256 balBefore = deployer.balance;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.prank(deployer);
        drop.addRecipients{ value: 10_000 ether }(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(_contentsOne[i].recipient.balance, _contentsOne[i].amount);
        }
        assertEq(deployer.balance, balBefore - 10_000 ether);
    }

    function test_state_processPayments_nativeToken_partial() public {
        vm.deal(deployer, 10_000 ether);

        uint256 balBefore = deployer.balance;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.prank(deployer);
        drop.addRecipients{ value: 10_000 ether }(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(_contentsOne[i].recipient.balance, _contentsOne[i].amount);
        }
        assertEq(deployer.balance, balBefore - 10_000 ether);
    }

    function test_revert_processPayments_incorrectNativeTokenAmt() public {
        vm.deal(deployer, 11_000 ether);

        uint256 incorrectAmt = 10_000 ether + 1;

        for (uint256 i = 0; i < 1000; i++) {
            _contentsOne[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.prank(deployer);
        vm.expectRevert("Incorrect native token amount");
        drop.addRecipients{ value: incorrectAmt }(_contentsOne);
    }

    function test_revert_processPayments_notAdmin() public {
        vm.prank(address(25));
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(address(25)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(0x00), 32)
            )
        );
        drop.addRecipients(_contentsOne);
    }

    function test_revert_processPayments_notApproved() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), 0);

        vm.startPrank(deployer);
        drop.addRecipients(_contentsOne);
        vm.expectRevert("Not balance or allowance");
        drop.processPayments(_contentsOne.length);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `reset`
    //////////////////////////////////////////////////////////////*/

    function test_state_resetRecipients() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        // do a reset
        vm.prank(deployer);
        drop.resetRecipients();

        // check state after reset
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0); // 0 pending payments after reset
        assertEq(drop.getAllAirdropPaymentsCancelled(0, countOne - 1).length, 300); // cancelled payments
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne); // processed count set equal to total payee count

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 3000 ether);
    }

    function test_state_resetRecipients_addMore() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // do a reset
        vm.prank(deployer);
        drop.resetRecipients();

        // check state after reset
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0); // 0 pending payments after reset
        assertEq(drop.getAllAirdropPaymentsCancelled(0, countOne - 1).length, 300); // cancelled payments
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne); // processed count set equal to total payee count

        // add more recipients
        vm.prank(deployer);
        drop.addRecipients(_contentsTwo);

        // check state
        assertEq(drop.getAllAirdropPayments(0, countOne + countTwo - 1).length, countOne + countTwo);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne + countTwo - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne + countTwo - 1).length, countTwo); // pending payments equal to count of new recipients added
        assertEq(drop.getAllAirdropPaymentsCancelled(0, countOne + countTwo - 1).length, 300); // cancelled payments
        assertEq(drop.payeeCount(), countOne + countTwo);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 3000 ether);
    }

    function test_state_resetRecipients_nativeToken() public {
        vm.deal(deployer, 10_000 ether);

        uint256 balBefore = deployer.balance;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne[i].tokenAddress = NATIVE_TOKEN;
        }

        vm.prank(deployer);
        drop.addRecipients{ value: 10_000 ether }(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, 0);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        // do a reset
        vm.prank(deployer);
        drop.resetRecipients();

        // check state after reset
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne - 300);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0); // 0 pending payments after reset
        assertEq(drop.getAllAirdropPaymentsCancelled(0, countOne - 1).length, 300); // cancelled payments
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne); // processed count set equal to total payee count

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(_contentsOne[i].recipient.balance, _contentsOne[i].amount);
        }
        assertEq(deployer.balance, balBefore - 7_000 ether); // native token amount gets refunded
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdrop(_contentsOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc20.balanceOf(_contentsOne[i].recipient), _contentsOne[i].amount);
        }
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
    }

    function test_revert_airdrop_notOwner() public {
        vm.prank(address(25));
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(address(25)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(0x00), 32)
            )
        );
        drop.airdrop(_contentsOne);
    }

    function test_revert_airdrop_notApproved() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(drop), 0);

        vm.startPrank(deployer);
        vm.expectRevert("Not balance or allowance");
        drop.airdrop(_contentsOne);
        vm.stopPrank();
    }
}
