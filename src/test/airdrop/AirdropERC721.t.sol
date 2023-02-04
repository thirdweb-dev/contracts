// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/airdrop/AirdropERC721.sol";

// Test imports
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract AirdropERC721Test is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    IAirdropERC721.AirdropContent[] internal _contentsOne;
    IAirdropERC721.AirdropContent[] internal _contentsTwo;

    uint256 countOne;
    uint256 countTwo;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        countOne = 1000;
        countTwo = 200;

        for (uint256 i = 0; i < countOne; i++) {
            _contentsOne.push(
                IAirdropERC721.AirdropContent({
                    tokenAddress: address(erc721),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i
                })
            );
        }

        for (uint256 i = countOne; i < countOne + countTwo; i++) {
            _contentsTwo.push(
                IAirdropERC721.AirdropContent({
                    tokenAddress: address(erc721),
                    tokenOwner: address(tokenOwner),
                    recipient: getActor(uint160(i)),
                    tokenId: i
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
        drop.processPayments(_contentsOne.length);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsProcessed(0, countOne - 1).length, countOne);
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, 0);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), countOne);

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }
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

        for (uint256 i = 0; i < 700; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }

        for (uint256 i = 700; i < 1000; i++) {
            assertEq(erc721.ownerOf(i), address(tokenOwner));
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

        vm.prank(deployer);
        drop.addRecipients(_contentsOne);
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(address(25)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(0x00), 32)
            )
        );
        vm.prank(address(25));
        drop.processPayments(countOne);
    }

    function test_revert_processPayments_notApproved() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), false);

        vm.startPrank(deployer);
        drop.addRecipients(_contentsOne);
        vm.expectRevert("Not owner or approved");
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

        for (uint256 i = 0; i < 700; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }
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

        for (uint256 i = 0; i < 700; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: stateless airdrop
    //////////////////////////////////////////////////////////////*/

    function test_state_airdrop() public {
        vm.prank(deployer);
        drop.airdrop(_contentsOne);

        for (uint256 i = 0; i < 1000; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
        }
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
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), false);

        vm.startPrank(deployer);
        vm.expectRevert("Not owner or approved");
        drop.airdrop(_contentsOne);
        vm.stopPrank();
    }
}
