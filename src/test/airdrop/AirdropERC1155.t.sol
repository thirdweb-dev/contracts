// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC1155.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC1155Test is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC1155.AirdropContent[] internal _contentsOne;
    IAirdropERC1155.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155(getContract("AirdropERC1155"));

        tokenOwner = getWallet();

        erc1155.mint(address(tokenOwner), 0, 1000);
        erc1155.mint(address(tokenOwner), 1, 2000);
        erc1155.mint(address(tokenOwner), 2, 3000);
        erc1155.mint(address(tokenOwner), 3, 4000);
        erc1155.mint(address(tokenOwner), 4, 5000);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(
                IAirdropERC1155.AirdropContent({
                    tokenAddress: address(erc1155),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i % 5,
                    amount: 5
                })
            );
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(
                IAirdropERC1155.AirdropContent({
                    tokenAddress: address(erc1155),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i % 5,
                    amount: 5
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
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 1000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 2000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 3), 3000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 4), 4000);
    }

    function test_state_processPayments_partial() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }
    }

    function test_revert_processPayments_notOwner() public {
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
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), false);

        vm.startPrank(deployer);
        drop.addRecipients(_contentsOne);
        vm.expectRevert("Not balance or approved");
        drop.processPayments(_contentsOne.length);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `cancelPayments`
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelPayments() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // check state before airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 300);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne - 300);

        // cancel payments
        vm.prank(deployer);
        drop.cancelPendingPayments(300);

        // check state after reset
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0); // 0 pending payments after reset
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne); // processed count set equal to total payee count

        IAirdropERC1155.CancelledPayments[] memory cancelledPayments = drop.getCancelledPaymentIndices();
        assertEq(cancelledPayments.length, 1);
        assertEq(cancelledPayments[0].startIndex, countOne - 300);
        assertEq(cancelledPayments[0].endIndex, countOne - 1);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }
    }

    function test_state_cancelPayments_addMore() public {
        vm.prank(deployer);
        drop.addRecipients(_contentsOne);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(countOne - 300);

        // cancel payments
        vm.prank(deployer);
        drop.cancelPendingPayments(300);

        // check state after reset
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0); // 0 pending payments after reset
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne); // processed count set equal to total payee count

        IAirdropERC1155.CancelledPayments[] memory cancelledPayments = drop.getCancelledPaymentIndices();
        assertEq(cancelledPayments.length, 1);
        assertEq(cancelledPayments[0].startIndex, countOne - 300);
        assertEq(cancelledPayments[0].endIndex, countOne - 1);

        // add more recipients
        vm.prank(deployer);
        drop.addRecipients(_contentsTwo);

        // check state
        assertEq(drop.getAllAirdropPayments(0, countOne + countTwo - 1).length, countOne + countTwo);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne + countTwo - 1).length, countTwo); // pending payments equal to count of new recipients added
        assertEq(drop.payeeCount(), countOne + countTwo);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < countOne - 300; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }

        // cancel more
        vm.prank(deployer);
        drop.cancelPendingPayments(100);

        cancelledPayments = drop.getCancelledPaymentIndices();
        assertEq(cancelledPayments.length, 2);
        assertEq(cancelledPayments[0].startIndex, countOne - 300);
        assertEq(cancelledPayments[0].endIndex, countOne - 1);
        assertEq(cancelledPayments[1].startIndex, countOne);
        assertEq(cancelledPayments[1].endIndex, countOne + 100 - 1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdrop(_contentsOne);

        for (uint256 i = 0; i < countOne; i++) {
            assertEq(erc1155.balanceOf(_contentsOne[i].recipient, i % 5), 5);
        }

        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 1000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 2000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 3), 3000);
        assertEq(erc1155.balanceOf(address(tokenOwner), 4), 4000);
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
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), false);

        vm.startPrank(deployer);
        vm.expectRevert("Not balance or approved");
        drop.airdrop(_contentsOne);
        vm.stopPrank();
    }
}

contract AirdropERC1155GasTest is BaseTest {
    AirdropERC1155 internal drop;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC1155(getContract("AirdropERC1155"));

        tokenOwner = getWallet();

        erc1155.mint(address(tokenOwner), 0, 1000);

        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(drop), true);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: gas benchmarks, etc.
    //////////////////////////////////////////////////////////////*/

    function test_safeTransferFrom_toEOA() public {
        vm.prank(address(tokenOwner));
        erc1155.safeTransferFrom(address(tokenOwner), address(0x123), 0, 10, "");
    }

    function test_safeTransferFrom_toContract() public {
        vm.prank(address(tokenOwner));
        erc1155.safeTransferFrom(address(tokenOwner), address(this), 0, 10, "");
    }

    function test_safeTransferFrom_toEOA_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        erc1155.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0, 10, "");
        console.log(gasleft());
    }

    function test_safeTransferFrom_toContract_gasOverride() public {
        vm.prank(address(tokenOwner));
        console.log(gasleft());
        erc1155.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0, 10, "");
        console.log(gasleft());
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
