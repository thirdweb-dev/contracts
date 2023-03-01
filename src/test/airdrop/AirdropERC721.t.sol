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
        assertEq(drop.getAllAirdropPaymentsPending(0, countOne - 1).length, countOne);
        assertEq(drop.payeeCount(), countOne);
        assertEq(drop.processedCount(), 0);

        // perform airdrop
        vm.prank(deployer);
        drop.processPayments(_contentsOne.length);

        // check state after airdrop
        assertEq(drop.getAllAirdropPayments(0, countOne - 1).length, countOne);
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

        IAirdropERC721.CancelledPayments[] memory cancelledPayments = drop.getCancelledPaymentIndices();
        assertEq(cancelledPayments.length, 1);
        assertEq(cancelledPayments[0].startIndex, countOne - 300);
        assertEq(cancelledPayments[0].endIndex, countOne - 1);

        for (uint256 i = 0; i < 700; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
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

        IAirdropERC721.CancelledPayments[] memory cancelledPayments = drop.getCancelledPaymentIndices();
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

        for (uint256 i = 0; i < 700; i++) {
            assertEq(erc721.ownerOf(i), _contentsOne[i].recipient);
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

contract AirdropERC721AuditTest is BaseTest {
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

    function test_NewRecipientsAreEmptyPreventingAirdrops() public {
        // create a memory array of one as the recipient array to use for this test
        IAirdropERC721.AirdropContent[] memory _c = new IAirdropERC721.AirdropContent[](1);
        _c[0] = _contentsOne[0];
        // add recipients the first time
        vm.prank(deployer);
        drop.addRecipients(_c);
        // everything should be normal at this point
        assertEq(drop.payeeCount(), 1);
        assertEq(drop.getAllAirdropPayments(0, 0).length, 1);
        assertEq(drop.payeeCount(), 1);
        // grab another recipient
        _c[0] = _contentsOne[1];
        // add this new one, this is where the issues occur
        vm.prank(deployer);
        drop.addRecipients(_c);
        // payee count is correct, everything seems fine
        assertEq(drop.payeeCount(), 2);
        // get all the airdrop payments to double check
        IAirdropERC721.AirdropContent[] memory _res = drop.getAllAirdropPayments(0, 1);
        // length seems fine
        assertEq(_res.length, 2);
        // first entry is correct
        assertEq(_res[0].tokenAddress, _contentsOne[0].tokenAddress);
        assertEq(_res[1].tokenAddress, _contentsOne[1].tokenAddress);
        assertEq(_res[1].tokenAddress == _contentsOne[1].tokenAddress, true);

        vm.prank(deployer);
        drop.processPayments(2);
    }
}

contract AirdropERC721GasTest is BaseTest {
    AirdropERC721 internal drop;

    Wallet internal tokenOwner;

    function setUp() public override {
        super.setUp();

        drop = AirdropERC721(getContract("AirdropERC721"));

        tokenOwner = getWallet();

        erc721.mint(address(tokenOwner), 1500);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(drop), true);

        vm.startPrank(address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: gas benchmarks, etc.
    //////////////////////////////////////////////////////////////*/

    function test_safeTransferFrom_toEOA() public {
        erc721.safeTransferFrom(address(tokenOwner), address(0x123), 0);
    }

    function test_safeTransferFrom_toContract() public {
        erc721.safeTransferFrom(address(tokenOwner), address(this), 0);
    }

    function test_safeTransferFrom_toEOA_gasOverride() public {
        console.log(gasleft());
        erc721.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(0x123), 0);
        console.log(gasleft());
    }

    function test_safeTransferFrom_toContract_gasOverride() public {
        console.log(gasleft());
        erc721.safeTransferFrom{ gas: 100_000 }(address(tokenOwner), address(this), 0);
        console.log(gasleft());
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
