// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TempPack } from "contracts/pack/TempPack.sol";
import { ITempPack } from "contracts/interfaces/ITempPack.sol";
import { ITokenBundle } from "contracts/feature/interface/ITokenBundle.sol";

// Test imports
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Wallet } from "./utils/Wallet.sol";
import "./utils/BaseTest.sol";

contract TempPackTest is BaseTest {
    /// @notice Emitted when a set of packs is created.
    event PackCreated(
        uint256 indexed packId,
        address indexed packCreator,
        address recipient,
        uint256 totalPacksCreated
    );

    /// @notice Emitted when a pack is opened.
    event PackOpened(
        uint256 indexed packId,
        address indexed opener,
        uint256 numOfPacksOpened,
        ITokenBundle.Token[] rewardUnitsDistributed
    );

    TempPack internal tempPack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    uint256[] internal amountsPerUnit;

    function setUp() public override {
        super.setUp();

        tempPack = TempPack(getContract("TempPack"));

        tokenOwner = getWallet();
        packUri = "ipfs://";

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 0,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );
        amountsPerUnit.push(5);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        amountsPerUnit.push(20 ether);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 1,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        amountsPerUnit.push(10 ether);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 2,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 3,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 4,
                totalAmount: 1
            })
        );
        amountsPerUnit.push(1);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 5);
        erc1155.mint(address(tokenOwner), 0, 100);

        tokenOwner.setAllowanceERC20(address(erc20), address(tempPack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(tempPack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(tempPack), true);

        vm.prank(deployer);
        tempPack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     */
    function test_state_createPack() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        assertEq(packId + 1, tempPack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, tempPack.uri(packId));
    }

    /*
     *  note: Testing state changes; token owner calls `createPack` to pack native tokens.
     */
    function test_state_createPack_nativeTokens() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.deal(address(tokenOwner), 100 ether);
        packContents.push(
            ITokenBundle.Token({
                assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 20 ether
            })
        );
        amountsPerUnit.push(1 ether);

        vm.prank(address(tokenOwner));
        tempPack.createPack{ value: 20 ether }(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        assertEq(packId + 1, tempPack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, tempPack.uri(packId));
    }

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     *        Only assets with ASSET_ROLE can be packed.
     */
    function test_state_createPack_withAssetRoleRestriction() public {
        vm.startPrank(deployer);
        tempPack.revokeRole(keccak256("ASSET_ROLE"), address(0));
        for (uint256 i = 0; i < packContents.length; i += 1) {
            tempPack.grantRole(keccak256("ASSET_ROLE"), packContents[i].assetContract);
        }
        vm.stopPrank();

        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        assertEq(packId + 1, tempPack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, tempPack.uri(packId));
    }

    /**
     *  note: Testing event emission; token owner calls `createPack` to pack owned tokens.
     */
    function test_event_createPack_PackCreated() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectEmit(true, true, true, true);
        emit PackCreated(packId, address(tokenOwner), recipient, 175);

        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.stopPrank();
    }

    /**
     *  note: Testing token balances; token owner calls `createPack` to pack owned tokens.
     */
    function test_balances_createPack() public {
        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 2000 ether);
        assertEq(erc20.balanceOf(address(tempPack)), 0);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tokenOwner));
        assertEq(erc721.ownerOf(1), address(tokenOwner));
        assertEq(erc721.ownerOf(2), address(tokenOwner));
        assertEq(erc721.ownerOf(3), address(tokenOwner));
        assertEq(erc721.ownerOf(4), address(tokenOwner));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
        assertEq(erc1155.balanceOf(address(tempPack), 0), 0);

        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(tempPack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tempPack));
        assertEq(erc721.ownerOf(1), address(tempPack));
        assertEq(erc721.ownerOf(2), address(tempPack));
        assertEq(erc721.ownerOf(3), address(tempPack));
        assertEq(erc721.ownerOf(4), address(tempPack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(tempPack), 0), 100);

        // TempPack wrapped token balance
        assertEq(tempPack.balanceOf(address(recipient), packId), 175);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack owned tokens.
     *        Only assets with ASSET_ROLE can be packed, but assets being packed don't have that role.
     */
    function test_revert_createPack_access_ASSET_ROLE() public {
        vm.prank(deployer);
        tempPack.revokeRole(keccak256("ASSET_ROLE"), address(0));

        address recipient = address(0x123);

        string memory errorMsg = string(
            abi.encodePacked(
                "Permissions: account ",
                Strings.toHexString(uint160(packContents[0].assetContract), 20),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("ASSET_ROLE")), 32)
            )
        );

        vm.prank(address(tokenOwner));
        vm.expectRevert(bytes(errorMsg));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack owned tokens, without MINTER_ROLE.
     */
    function test_revert_createPack_access_MINTER_ROLE() public {
        vm.prank(address(tokenOwner));
        tempPack.renounceRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        address recipient = address(0x123);

        string memory errorMsg = string(
            abi.encodePacked(
                "Permissions: account ",
                Strings.toHexString(uint160(address(tokenOwner)), 20),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
            )
        );

        vm.prank(address(tokenOwner));
        vm.expectRevert(bytes(errorMsg));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with insufficient value when packing native tokens.
     */
    function test_revert_createPack_nativeTokens_insufficientValue() public {
        address recipient = address(0x123);

        vm.deal(address(tokenOwner), 100 ether);

        packContents.push(
            ITokenBundle.Token({
                assetContract: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 20 ether
            })
        );
        amountsPerUnit.push(1 ether);

        vm.prank(address(tokenOwner));
        vm.expectRevert("msg.value != amount");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC20 tokens.
     */
    function test_revert_createPack_notOwner_ERC20() public {
        tokenOwner.transferERC20(address(erc20), address(0x12), 1000 ether);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC721 tokens.
     */
    function test_revert_createPack_notOwner_ERC721() public {
        tokenOwner.transferERC721(address(erc721), address(0x12), 0);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC1155 tokens.
     */
    function test_revert_createPack_notOwner_ERC1155() public {
        tokenOwner.transferERC1155(address(erc1155), address(0x12), 0, 100, "");

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC20 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC20() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(tempPack), 0);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC20: insufficient allowance");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC721 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC721() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(tempPack), false);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC1155 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC1155() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(tempPack), false);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC1155: caller is not owner nor approved");
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with no tokens to pack.
     */
    function test_revert_createPack_noTokensToPack() public {
        ITokenBundle.Token[] memory emptyContent;
        uint256[] memory amounts;

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("nothing to pack");
        tempPack.createPack(emptyContent, amounts, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with unequal length of contents and amounts.
     */
    function test_revert_createPack_invalidAmounts() public {
        uint256[] memory amounts;

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("invalid per unit amounts");
        tempPack.createPack(packContents, amounts, packUri, 0, 1, recipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_state_openPack() public {
        vm.warp(1000);
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        tempPack.openPack(packId, 1);

        assertEq(packUri, tempPack.uri(packId));
        assertEq(tempPack.totalSupply(packId), 174);

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, 8);
    }

    /**
     *  note: Testing event emission; pack owner calls `openPack` to open owned packs.
     */
    function test_event_openPack_PackOpened() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        ITokenBundle.Token[] memory emptyRewardUnitsForTestingEvent;

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.expectEmit(true, true, false, false);
        emit PackOpened(packId, recipient, 1, emptyRewardUnitsForTestingEvent);

        vm.prank(recipient, recipient);
        tempPack.openPack(packId, 1);
    }

    function test_balances_openPack() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(recipient)), 0);
        assertEq(erc20.balanceOf(address(tempPack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tempPack));
        assertEq(erc721.ownerOf(1), address(tempPack));
        assertEq(erc721.ownerOf(2), address(tempPack));
        assertEq(erc721.ownerOf(3), address(tempPack));
        assertEq(erc721.ownerOf(4), address(tempPack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(recipient), 0), 0);
        assertEq(erc1155.balanceOf(address(tempPack), 0), 100);

        vm.prank(recipient, recipient);
        tempPack.openPack(packId, 1);

        if (erc20.balanceOf(address(recipient)) > 0) {
            assertTrue(
                erc20.balanceOf(address(recipient)) == 10 ether || erc20.balanceOf(address(recipient)) == 20 ether
            );
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else if (erc1155.balanceOf(address(recipient), 0) > 0) {
            assertEq(erc1155.balanceOf(address(recipient), 0), 5);
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else if (erc721.balanceOf(address(recipient)) > 0) {
            assertEq(erc721.balanceOf(address(recipient)), 1);
            assertEq(tempPack.balanceOf(address(recipient), packId), 174);
        } else {
            assertEq(tempPack.balanceOf(address(recipient), packId), 178);
        }
    }

    /**
     *  note: Testing revert condition; caller of `openPack` is not EOA.
     */
    function test_revert_openPack_notEOA() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.startPrank(recipient, address(27));
        vm.expectRevert("opener must be eoa");
        tempPack.openPack(packId, 1);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` to open more than owned packs.
     */
    function test_revert_openPack_openMoreThanOwned() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.startPrank(recipient, recipient);
        vm.expectRevert("opening more than owned");
        tempPack.openPack(packId, 180);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` before start timestamp.
     */
    function test_revert_openPack_openBeforeStart() public {
        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 1000, 1, recipient);

        vm.startPrank(recipient, recipient);
        vm.expectRevert("cannot open yet");
        tempPack.openPack(packId, 1);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` with pack-id non-existent or not owned.
     */
    function test_revert_openPack_invalidPackId() public {
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(packContents, amountsPerUnit, packUri, 0, 1, recipient);

        vm.startPrank(recipient, recipient);
        vm.expectRevert("opening more than owned");
        tempPack.openPack(2, 1);
    }

    
    /*///////////////////////////////////////////////////////////////
                            Fuzz testing
    //////////////////////////////////////////////////////////////*/


    uint256 internal constant MAX_TOKENS = 10;

    function getTokensToPack(uint256 len) internal returns (ITokenBundle.Token[] memory tokensToPack, uint256[] memory amounts) {
        vm.assume(len < MAX_TOKENS);
        tokensToPack = new ITokenBundle.Token[](len);
        amounts = new uint256[](len);

        for (uint256 i = 0; i < len; i += 1) {
            uint256 random = uint256(keccak256(abi.encodePacked(len + i))) % MAX_TOKENS;
            uint256 selector = random % 3;

            if (selector == 0) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc20),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: random * 10 ether
                });
                amounts[i] = 10 ether;

                erc20.mint(address(tokenOwner), tokensToPack[i].totalAmount);
            } else if (selector == 1) {
                uint256 tokenId = erc721.nextTokenIdToMint();

                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc721),
                    tokenType: ITokenBundle.TokenType.ERC721,
                    tokenId: tokenId,
                    totalAmount: 1
                });
                amounts[i] = 1;

                erc721.mint(address(tokenOwner), 1);
            } else if (selector == 2) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc1155),
                    tokenType: ITokenBundle.TokenType.ERC1155,
                    tokenId: random,
                    totalAmount: random * 10
                });
                amounts[i] = 10;

                erc1155.mint(address(tokenOwner), tokensToPack[i].tokenId, tokensToPack[i].totalAmount);
            }
        }
    }

    function test_fuzz_state_createPack(uint256 x) public {
        (ITokenBundle.Token[] memory tokensToPack, uint256[] memory amounts) = getTokensToPack(x);
        if (tokensToPack.length == 0) {
            return;
        }

        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        tempPack.createPack(tokensToPack, amounts, packUri, 0, 1, recipient);

        assertEq(packId + 1, tempPack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = tempPack.getPackContents(packId);
        assertEq(packed.length, tokensToPack.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, tokensToPack[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(tokensToPack[i].tokenType));
            assertEq(packed[i].tokenId, tokensToPack[i].tokenId);
            assertEq(packed[i].totalAmount, tokensToPack[i].totalAmount);
        }

        assertEq(packUri, tempPack.uri(packId));
    }

    function test_fuzz_state_openPack(uint256 x) public {
        (ITokenBundle.Token[] memory tokensToPack, uint256[] memory amounts) = getTokensToPack(x);
        if (tokensToPack.length == 0) {
            return;
        }

        uint256 packId = tempPack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = tempPack.createPack(tokensToPack, amounts, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        tempPack.openPack(packId, 1);

        assertEq(packUri, tempPack.uri(packId));

        if (erc20.balanceOf(address(recipient)) > 0) {
            assertTrue(
                erc20.balanceOf(address(recipient)) == 10 ether
            );
            assertEq(tempPack.balanceOf(address(recipient), packId), totalSupply - 1);
        } else if (erc1155.balanceOf(address(recipient), 0) > 0) {
            assertEq(erc1155.balanceOf(address(recipient), 0), 10);
            assertEq(tempPack.balanceOf(address(recipient), packId), totalSupply - 1);
        } else if (erc721.balanceOf(address(recipient)) > 0) {
            assertEq(erc721.balanceOf(address(recipient)), 1);
            assertEq(tempPack.balanceOf(address(recipient), packId), totalSupply - 1);
        } else {
            assertEq(tempPack.balanceOf(address(recipient), packId), totalSupply - 1);
        }
    }
}
