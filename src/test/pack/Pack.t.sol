// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { Pack, IERC2981Upgradeable, IERC721Receiver, IERC1155Upgradeable } from "contracts/prebuilts/pack/Pack.sol";
import { IPack } from "contracts/prebuilts/interface/IPack.sol";
import { ITokenBundle } from "contracts/extension/interface/ITokenBundle.sol";
import { CurrencyTransferLib } from "contracts/lib/CurrencyTransferLib.sol";

// Test imports
import { MockERC20 } from "../mocks/MockERC20.sol";
import { Wallet } from "../utils/Wallet.sol";
import "../utils/BaseTest.sol";

contract PackTest is BaseTest {
    /// @notice Emitted when a set of packs is created.
    event PackCreated(uint256 indexed packId, address recipient, uint256 totalPacksCreated);

    /// @notice Emitted when a pack is opened.
    event PackOpened(
        uint256 indexed packId,
        address indexed opener,
        uint256 numOfPacksOpened,
        ITokenBundle.Token[] rewardUnitsDistributed
    );

    Pack internal pack;

    Wallet internal tokenOwner;
    string internal packUri;
    ITokenBundle.Token[] internal packContents;
    ITokenBundle.Token[] internal additionalContents;
    uint256[] internal numOfRewardUnits;
    uint256[] internal additionalContentsRewardUnits;

    function setUp() public override {
        super.setUp();

        pack = Pack(payable(getContract("Pack")));

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
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 0,
                totalAmount: 100
            })
        );
        numOfRewardUnits.push(20);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        numOfRewardUnits.push(50);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 1,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 2,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        numOfRewardUnits.push(100);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 3,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 4,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc721),
                tokenType: ITokenBundle.TokenType.ERC721,
                tokenId: 5,
                totalAmount: 1
            })
        );
        numOfRewardUnits.push(1);

        packContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 1,
                totalAmount: 500
            })
        );
        numOfRewardUnits.push(50);

        erc20.mint(address(tokenOwner), 2000 ether);
        erc721.mint(address(tokenOwner), 6);
        erc1155.mint(address(tokenOwner), 0, 100);
        erc1155.mint(address(tokenOwner), 1, 500);

        // additional contents, to check `addPackContents`
        additionalContents.push(
            ITokenBundle.Token({
                assetContract: address(erc1155),
                tokenType: ITokenBundle.TokenType.ERC1155,
                tokenId: 2,
                totalAmount: 200
            })
        );
        additionalContentsRewardUnits.push(50);

        additionalContents.push(
            ITokenBundle.Token({
                assetContract: address(erc20),
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: 1000 ether
            })
        );
        additionalContentsRewardUnits.push(100);

        tokenOwner.setAllowanceERC20(address(erc20), address(pack), type(uint256).max);
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), true);
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), true);

        vm.prank(deployer);
        pack.grantRole(keccak256("MINTER_ROLE"), address(tokenOwner));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_revert_addPackContents_RandomAccountGrief() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        // random address tries to transfer zero amount
        address randomAccount = address(0x123);
        vm.prank(randomAccount);
        pack.safeTransferFrom(randomAccount, address(567), packId, 0, ""); // zero transfer

        // canUpdatePack should remain true, since no packs were transferred
        assertTrue(pack.canUpdatePack(packId));

        erc20.mint(address(tokenOwner), 1000 ether);
        erc1155.mint(address(tokenOwner), 2, 200);

        vm.prank(address(tokenOwner));
        // Should not revert
        pack.addPackContents(packId, additionalContents, additionalContentsRewardUnits, recipient);
    }

    function test_checkForwarders() public {
        assertFalse(pack.isTrustedForwarder(eoaForwarder));
        assertFalse(pack.isTrustedForwarder(forwarder));
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `createPack`
    //////////////////////////////////////////////////////////////*/

    function test_interface() public pure {
        console2.logBytes4(type(IERC20).interfaceId);
        console2.logBytes4(type(IERC721).interfaceId);
        console2.logBytes4(type(IERC1155).interfaceId);
    }

    function test_supportsInterface() public {
        assertEq(pack.supportsInterface(type(IERC2981Upgradeable).interfaceId), true);
        assertEq(pack.supportsInterface(type(IERC721Receiver).interfaceId), true);
        assertEq(pack.supportsInterface(type(IERC1155Receiver).interfaceId), true);
        assertEq(pack.supportsInterface(type(IERC1155Upgradeable).interfaceId), true);
    }

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     */
    function test_state_createPack() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        assertEq(packId + 1, pack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, pack.uri(packId));
    }

    /*
     *  note: Testing state changes; token owner calls `createPack` to pack native tokens.
     */
    function test_state_createPack_nativeTokens() public {
        uint256 packId = pack.nextTokenIdToMint();
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
        numOfRewardUnits.push(20);

        vm.prank(address(tokenOwner));
        pack.createPack{ value: 20 ether }(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        assertEq(packId + 1, pack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, pack.uri(packId));
    }

    /**
     *  note: Testing state changes; token owner calls `createPack` to pack owned tokens.
     *        Only assets with ASSET_ROLE can be packed.
     */
    function test_state_createPack_withAssetRoleRestriction() public {
        vm.startPrank(deployer);
        pack.revokeRole(keccak256("ASSET_ROLE"), address(0));
        for (uint256 i = 0; i < packContents.length; i += 1) {
            if (!pack.hasRole(keccak256("ASSET_ROLE"), packContents[i].assetContract)) {
                pack.grantRole(keccak256("ASSET_ROLE"), packContents[i].assetContract);
            }
        }
        vm.stopPrank();

        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        assertEq(packId + 1, pack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        assertEq(packUri, pack.uri(packId));
    }

    /**
     *  note: Testing event emission; token owner calls `createPack` to pack owned tokens.
     */
    function test_event_createPack_PackCreated() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectEmit(true, true, true, true);
        emit PackCreated(packId, recipient, 226);

        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        vm.stopPrank();
    }

    /**
     *  note: Testing token balances; token owner calls `createPack` to pack owned tokens.
     */
    function test_balances_createPack() public {
        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 2000 ether);
        assertEq(erc20.balanceOf(address(pack)), 0);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(tokenOwner));
        assertEq(erc721.ownerOf(1), address(tokenOwner));
        assertEq(erc721.ownerOf(2), address(tokenOwner));
        assertEq(erc721.ownerOf(3), address(tokenOwner));
        assertEq(erc721.ownerOf(4), address(tokenOwner));
        assertEq(erc721.ownerOf(5), address(tokenOwner));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 100);
        assertEq(erc1155.balanceOf(address(pack), 0), 0);

        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 500);
        assertEq(erc1155.balanceOf(address(pack), 1), 0);

        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(pack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(pack));
        assertEq(erc721.ownerOf(1), address(pack));
        assertEq(erc721.ownerOf(2), address(pack));
        assertEq(erc721.ownerOf(3), address(pack));
        assertEq(erc721.ownerOf(4), address(pack));
        assertEq(erc721.ownerOf(5), address(pack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(pack), 0), 100);

        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 0);
        assertEq(erc1155.balanceOf(address(pack), 1), 500);

        // Pack wrapped token balance
        assertEq(pack.balanceOf(address(recipient), packId), totalSupply);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack owned tokens.
     *        Only assets with ASSET_ROLE can be packed, but assets being packed don't have that role.
     */
    function test_revert_createPack_access_ASSET_ROLE() public {
        vm.prank(deployer);
        pack.revokeRole(keccak256("ASSET_ROLE"), address(0));

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(erc721),
                keccak256("ASSET_ROLE")
            )
        );
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack owned tokens, without MINTER_ROLE.
     */
    function test_revert_createPack_access_MINTER_ROLE() public {
        vm.prank(address(tokenOwner));
        pack.renounceRole(keccak256("MINTER_ROLE"), address(tokenOwner));

        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(tokenOwner),
                keccak256("MINTER_ROLE")
            )
        );
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
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
        numOfRewardUnits.push(1);

        vm.prank(address(tokenOwner));
        vm.expectRevert(
            abi.encodeWithSelector(CurrencyTransferLib.CurrencyTransferLibMismatchedValue.selector, 0, 20 ether)
        );
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC20 tokens.
     */
    function test_revert_createPack_notOwner_ERC20() public {
        tokenOwner.transferERC20(address(erc20), address(0x12), 1000 ether);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC721 tokens.
     */
    function test_revert_createPack_notOwner_ERC721() public {
        tokenOwner.transferERC721(address(erc721), address(0x12), 0);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-owned ERC1155 tokens.
     */
    function test_revert_createPack_notOwner_ERC1155() public {
        tokenOwner.transferERC1155(address(erc1155), address(0x12), 0, 100, "");

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC1155: insufficient balance for transfer");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC20 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC20() public {
        tokenOwner.setAllowanceERC20(address(erc20), address(pack), 0);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC20: insufficient allowance");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC721 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC721() public {
        tokenOwner.setApprovalForAllERC721(address(erc721), address(pack), false);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC721: caller is not token owner or approved");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack un-approved ERC1155 tokens.
     */
    function test_revert_createPack_notApprovedTransfer_ERC1155() public {
        tokenOwner.setApprovalForAllERC1155(address(erc1155), address(pack), false);

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ERC1155: caller is not token owner or approved");
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with invalid token-type.
     */
    function test_revert_createPack_invalidTokenType() public {
        ITokenBundle.Token[] memory invalidContent = new ITokenBundle.Token[](1);
        uint256[] memory rewardUnits = new uint256[](1);

        invalidContent[0] = ITokenBundle.Token({
            assetContract: address(erc721),
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 1
        });
        rewardUnits[0] = 1;

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("!TokenType");
        pack.createPack(invalidContent, rewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with total-amount as 0.
     */
    function test_revert_createPack_zeroTotalAmount() public {
        ITokenBundle.Token[] memory invalidContent = new ITokenBundle.Token[](1);
        uint256[] memory rewardUnits = new uint256[](1);

        invalidContent[0] = ITokenBundle.Token({
            assetContract: address(erc20),
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 0
        });
        rewardUnits[0] = 10;

        address recipient = address(0x123);

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("0 amt");
        pack.createPack(invalidContent, rewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with no tokens to pack.
     */
    function test_revert_createPack_noTokensToPack() public {
        ITokenBundle.Token[] memory emptyContent;
        uint256[] memory rewardUnits;

        address recipient = address(0x123);

        bytes memory err = "!Len";
        vm.startPrank(address(tokenOwner));
        vm.expectRevert(err);
        pack.createPack(emptyContent, rewardUnits, packUri, 0, 1, recipient);
    }

    /**
     *  note: Testing revert condition; token owner calls `createPack` with unequal length of contents and rewardUnits.
     */
    function test_revert_createPack_invalidRewardUnits() public {
        uint256[] memory rewardUnits;

        address recipient = address(0x123);

        bytes memory err = "!Len";
        vm.startPrank(address(tokenOwner));
        vm.expectRevert(err);
        pack.createPack(packContents, rewardUnits, packUri, 0, 1, recipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `addPackContents`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; token owner calls `addPackContents` to pack more tokens.
     */
    function test_state_addPackContents() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, packContents[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(packContents[i].tokenType));
            assertEq(packed[i].tokenId, packContents[i].tokenId);
            assertEq(packed[i].totalAmount, packContents[i].totalAmount);
        }

        erc20.mint(address(tokenOwner), 1000 ether);
        erc1155.mint(address(tokenOwner), 2, 200);

        vm.prank(address(tokenOwner));
        pack.addPackContents(packId, additionalContents, additionalContentsRewardUnits, recipient);

        (packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length + additionalContents.length);
        for (uint256 i = packContents.length; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, additionalContents[i - packContents.length].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(additionalContents[i - packContents.length].tokenType));
            assertEq(packed[i].tokenId, additionalContents[i - packContents.length].tokenId);
            assertEq(packed[i].totalAmount, additionalContents[i - packContents.length].totalAmount);
        }
    }

    /**
     *  note: Testing token balances; token owner calls `addPackContents` to pack more tokens
     *        in an already existing pack.
     */
    function test_balances_addPackContents() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(pack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(pack));
        assertEq(erc721.ownerOf(1), address(pack));
        assertEq(erc721.ownerOf(2), address(pack));
        assertEq(erc721.ownerOf(3), address(pack));
        assertEq(erc721.ownerOf(4), address(pack));
        assertEq(erc721.ownerOf(5), address(pack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(tokenOwner), 0), 0);
        assertEq(erc1155.balanceOf(address(pack), 0), 100);

        assertEq(erc1155.balanceOf(address(tokenOwner), 1), 0);
        assertEq(erc1155.balanceOf(address(pack), 1), 500);

        // Pack wrapped token balance
        assertEq(pack.balanceOf(address(recipient), packId), totalSupply);

        erc20.mint(address(tokenOwner), 1000 ether);
        erc1155.mint(address(tokenOwner), 2, 200);

        vm.prank(address(tokenOwner));
        (uint256 newTotalSupply, uint256 additionalSupply) = pack.addPackContents(
            packId,
            additionalContents,
            additionalContentsRewardUnits,
            recipient
        );

        // ERC20 balance after adding more tokens
        assertEq(erc20.balanceOf(address(tokenOwner)), 0);
        assertEq(erc20.balanceOf(address(pack)), 3000 ether);

        // ERC1155 balance after adding more tokens
        assertEq(erc1155.balanceOf(address(tokenOwner), 2), 0);
        assertEq(erc1155.balanceOf(address(pack), 2), 200);

        // Pack wrapped token balance
        assertEq(pack.balanceOf(address(recipient), packId), newTotalSupply);
        assertEq(totalSupply + additionalSupply, newTotalSupply);
    }

    /**
     *  note: Testing revert condition; non-creator calls `addPackContents`.
     */
    function test_revert_addPackContents_NotMinterRole() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        address randomAccount = address(0x123);

        vm.prank(randomAccount);
        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                randomAccount,
                keccak256("MINTER_ROLE")
            )
        );
        pack.addPackContents(packId, additionalContents, additionalContentsRewardUnits, recipient);
    }

    /**
     *  note: Testing revert condition; adding tokens to non-existent pack.
     */
    function test_revert_addPackContents_PackNonExistent() public {
        vm.prank(address(tokenOwner));
        vm.expectRevert("!Allowed");
        pack.addPackContents(0, packContents, numOfRewardUnits, address(1));
    }

    /**
     *  note: Testing revert condition; adding tokens after packs have been distributed.
     */
    function test_revert_addPackContents_CantUpdateAnymore() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        vm.prank(recipient);
        pack.safeTransferFrom(recipient, address(567), packId, 1, "");

        vm.prank(address(tokenOwner));
        vm.expectRevert("!Allowed");
        pack.addPackContents(packId, additionalContents, additionalContentsRewardUnits, recipient);
    }

    /**
     *  note: Testing revert condition; adding tokens with a different recipient.
     */
    function test_revert_addPackContents_NotRecipient() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        address randomRecipient = address(0x12345);

        bytes memory err = "!Bal";
        vm.expectRevert(err);
        vm.prank(address(tokenOwner));
        pack.addPackContents(packId, additionalContents, additionalContentsRewardUnits, randomRecipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `openPack`
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; pack owner calls `openPack` to redeem underlying rewards.
     */
    function test_state_openPack() public {
        vm.warp(1000);
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 3;
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(packContents, numOfRewardUnits, packUri, 0, 2, recipient);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardUnits = pack.openPack(packId, packsToOpen);
        console2.log("total reward units: ", rewardUnits.length);

        for (uint256 i = 0; i < rewardUnits.length; i++) {
            console2.log("----- reward unit number: ", i, "------");
            console2.log("asset contract: ", rewardUnits[i].assetContract);
            console2.log("token type: ", uint256(rewardUnits[i].tokenType));
            console2.log("tokenId: ", rewardUnits[i].tokenId);
            if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC20) {
                console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
            } else {
                console2.log("total amount: ", rewardUnits[i].totalAmount);
            }
            console2.log("");
        }

        assertEq(packUri, pack.uri(packId));
        assertEq(pack.totalSupply(packId), totalSupply - packsToOpen);

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, packContents.length);
    }

    /**
     *  note: Total amount should get updated correctly -- reduce perUnitAmount from totalAmount of the token content, for each reward
     */
    function test_state_openPack_totalAmounts_ERC721() public {
        vm.warp(1000);
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 1;
        address recipient = address(1);

        erc721.mint(address(tokenOwner), 6);

        ITokenBundle.Token[] memory tempContents = new ITokenBundle.Token[](1);
        uint256[] memory tempNumRewardUnits = new uint256[](1);

        tempContents[0] = ITokenBundle.Token({
            assetContract: address(erc721),
            tokenType: ITokenBundle.TokenType.ERC721,
            tokenId: 0,
            totalAmount: 1
        });
        tempNumRewardUnits[0] = 1;

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(tempContents, tempNumRewardUnits, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardUnits = pack.openPack(packId, packsToOpen);

        assertEq(packUri, pack.uri(packId));
        assertEq(pack.totalSupply(packId), totalSupply - packsToOpen);

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, tempContents.length);
        assertEq(packed[0].totalAmount, tempContents[0].totalAmount - rewardUnits[0].totalAmount);
    }

    /**
     *  note: Total amount should get updated correctly -- reduce perUnitAmount from totalAmount of the token content, for each reward
     */
    function test_state_openPack_totalAmounts_ERC1155() public {
        vm.warp(1000);
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 1;
        address recipient = address(1);

        erc1155.mint(address(tokenOwner), 0, 100);

        ITokenBundle.Token[] memory tempContents = new ITokenBundle.Token[](1);
        uint256[] memory tempNumRewardUnits = new uint256[](1);

        tempContents[0] = ITokenBundle.Token({
            assetContract: address(erc1155),
            tokenType: ITokenBundle.TokenType.ERC1155,
            tokenId: 0,
            totalAmount: 100
        });
        tempNumRewardUnits[0] = 10;

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(tempContents, tempNumRewardUnits, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardUnits = pack.openPack(packId, packsToOpen);

        assertEq(packUri, pack.uri(packId));
        assertEq(pack.totalSupply(packId), totalSupply - packsToOpen);

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, tempContents.length);
        assertEq(packed[0].totalAmount, tempContents[0].totalAmount - rewardUnits[0].totalAmount);
    }

    /**
     *  note: Total amount should get updated correctly -- reduce perUnitAmount from totalAmount of the token content, for each reward
     */
    function test_state_openPack_totalAmounts_ERC20() public {
        vm.warp(1000);
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 1;
        address recipient = address(1);

        erc20.mint(address(tokenOwner), 2000 ether);

        ITokenBundle.Token[] memory tempContents = new ITokenBundle.Token[](1);
        uint256[] memory tempNumRewardUnits = new uint256[](1);

        tempContents[0] = ITokenBundle.Token({
            assetContract: address(erc20),
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 1000 ether
        });
        tempNumRewardUnits[0] = 50;

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(tempContents, tempNumRewardUnits, packUri, 0, 1, recipient);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardUnits = pack.openPack(packId, packsToOpen);

        assertEq(packUri, pack.uri(packId));
        assertEq(pack.totalSupply(packId), totalSupply - packsToOpen);

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, tempContents.length);
        assertEq(packed[0].totalAmount, tempContents[0].totalAmount - rewardUnits[0].totalAmount);
    }

    /**
     *  note: Testing event emission; pack owner calls `openPack` to open owned packs.
     */
    function test_event_openPack_PackOpened() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);

        ITokenBundle.Token[] memory emptyRewardUnitsForTestingEvent;

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        vm.expectEmit(true, true, false, false);
        emit PackOpened(packId, recipient, 1, emptyRewardUnitsForTestingEvent);

        vm.prank(recipient, recipient);
        pack.openPack(packId, 1);
    }

    function test_balances_openPack() public {
        uint256 packId = pack.nextTokenIdToMint();
        uint256 packsToOpen = 3;
        address recipient = address(1);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 2, recipient);

        // ERC20 balance
        assertEq(erc20.balanceOf(address(recipient)), 0);
        assertEq(erc20.balanceOf(address(pack)), 2000 ether);

        // ERC721 balance
        assertEq(erc721.ownerOf(0), address(pack));
        assertEq(erc721.ownerOf(1), address(pack));
        assertEq(erc721.ownerOf(2), address(pack));
        assertEq(erc721.ownerOf(3), address(pack));
        assertEq(erc721.ownerOf(4), address(pack));
        assertEq(erc721.ownerOf(5), address(pack));

        // ERC1155 balance
        assertEq(erc1155.balanceOf(address(recipient), 0), 0);
        assertEq(erc1155.balanceOf(address(pack), 0), 100);

        assertEq(erc1155.balanceOf(address(recipient), 1), 0);
        assertEq(erc1155.balanceOf(address(pack), 1), 500);

        vm.prank(recipient, recipient);
        ITokenBundle.Token[] memory rewardUnits = pack.openPack(packId, packsToOpen);
        console2.log("total reward units: ", rewardUnits.length);

        uint256 erc20Amount;
        uint256[] memory erc1155Amounts = new uint256[](2);
        uint256 erc721Amount;

        for (uint256 i = 0; i < rewardUnits.length; i++) {
            console2.log("----- reward unit number: ", i, "------");
            console2.log("asset contract: ", rewardUnits[i].assetContract);
            console2.log("token type: ", uint256(rewardUnits[i].tokenType));
            console2.log("tokenId: ", rewardUnits[i].tokenId);
            if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC20) {
                console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
                console.log("balance of recipient: ", erc20.balanceOf(address(recipient)) / 1 ether, "ether");
                erc20Amount += rewardUnits[i].totalAmount;
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC1155) {
                console2.log("total amount: ", rewardUnits[i].totalAmount);
                console.log("balance of recipient: ", erc1155.balanceOf(address(recipient), rewardUnits[i].tokenId));
                erc1155Amounts[rewardUnits[i].tokenId] += rewardUnits[i].totalAmount;
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC721) {
                console2.log("total amount: ", rewardUnits[i].totalAmount);
                console.log("balance of recipient: ", erc721.balanceOf(address(recipient)));
                erc721Amount += rewardUnits[i].totalAmount;
            }
            console2.log("");
        }

        assertEq(erc20.balanceOf(address(recipient)), erc20Amount);
        assertEq(erc721.balanceOf(address(recipient)), erc721Amount);

        for (uint256 i = 0; i < erc1155Amounts.length; i += 1) {
            assertEq(erc1155.balanceOf(address(recipient), i), erc1155Amounts[i]);
        }
    }

    /**
     *  note: Testing revert condition; caller of `openPack` is not EOA.
     */
    function test_revert_openPack_notEOA() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        vm.startPrank(recipient, address(27));
        string memory err = "!EOA";
        vm.expectRevert(bytes(err));
        pack.openPack(packId, 1);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` to open more than owned packs.
     */
    function test_revert_openPack_openMoreThanOwned() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        bytes memory err = "!Bal";
        vm.startPrank(recipient, recipient);
        vm.expectRevert(err);
        pack.openPack(packId, totalSupply + 1);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` before start timestamp.
     */
    function test_revert_openPack_openBeforeStart() public {
        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);
        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 1000, 1, recipient);

        vm.startPrank(recipient, recipient);
        vm.expectRevert("cant open");
        pack.openPack(packId, 1);
    }

    /**
     *  note: Testing revert condition; pack owner calls `openPack` with pack-id non-existent or not owned.
     */
    function test_revert_openPack_invalidPackId() public {
        address recipient = address(0x123);

        vm.prank(address(tokenOwner));
        pack.createPack(packContents, numOfRewardUnits, packUri, 0, 1, recipient);

        bytes memory err = "!Bal";
        vm.startPrank(recipient, recipient);
        vm.expectRevert(err);
        pack.openPack(2, 1);
    }

    /*///////////////////////////////////////////////////////////////
                            Fuzz testing
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_TOKENS = 2000;

    function getTokensToPack(
        uint256 len
    ) internal returns (ITokenBundle.Token[] memory tokensToPack, uint256[] memory rewardUnits) {
        vm.assume(len < MAX_TOKENS);
        tokensToPack = new ITokenBundle.Token[](len);
        rewardUnits = new uint256[](len);

        for (uint256 i = 0; i < len; i += 1) {
            uint256 random = uint256(keccak256(abi.encodePacked(len + i))) % MAX_TOKENS;
            uint256 selector = random % 4;

            if (selector == 0) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc20),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: (random + 1) * 10 ether
                });
                rewardUnits[i] = random + 1;

                erc20.mint(address(tokenOwner), tokensToPack[i].totalAmount);
            } else if (selector == 1) {
                uint256 tokenId = erc721.nextTokenIdToMint();

                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc721),
                    tokenType: ITokenBundle.TokenType.ERC721,
                    tokenId: tokenId,
                    totalAmount: 1
                });
                rewardUnits[i] = 1;

                erc721.mint(address(tokenOwner), 1);
            } else if (selector == 2) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(erc1155),
                    tokenType: ITokenBundle.TokenType.ERC1155,
                    tokenId: random,
                    totalAmount: (random + 1) * 10
                });
                rewardUnits[i] = random + 1;

                erc1155.mint(address(tokenOwner), tokensToPack[i].tokenId, tokensToPack[i].totalAmount);
            } else if (selector == 3) {
                tokensToPack[i] = ITokenBundle.Token({
                    assetContract: address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
                    tokenType: ITokenBundle.TokenType.ERC20,
                    tokenId: 0,
                    totalAmount: 5 ether
                });
                rewardUnits[i] = 5;
            }
        }
    }

    function checkBalances(
        ITokenBundle.Token[] memory rewardUnits,
        address
    )
        internal
        pure
        returns (uint256 nativeTokenAmount, uint256 erc20Amount, uint256[] memory erc1155Amounts, uint256 erc721Amount)
    {
        erc1155Amounts = new uint256[](MAX_TOKENS);

        for (uint256 i = 0; i < rewardUnits.length; i++) {
            // console2.log("----- reward unit number: ", i, "------");
            // console2.log("asset contract: ", rewardUnits[i].assetContract);
            // console2.log("token type: ", uint256(rewardUnits[i].tokenType));
            // console2.log("tokenId: ", rewardUnits[i].tokenId);
            if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC20) {
                if (rewardUnits[i].assetContract == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                    // console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
                    // console.log("balance of recipient: ", address(recipient).balance);
                    nativeTokenAmount += rewardUnits[i].totalAmount;
                } else {
                    // console2.log("total amount: ", rewardUnits[i].totalAmount / 1 ether, "ether");
                    // console.log("balance of recipient: ", erc20.balanceOf(address(recipient)) / 1 ether, "ether");
                    erc20Amount += rewardUnits[i].totalAmount;
                }
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC1155) {
                // console2.log("total amount: ", rewardUnits[i].totalAmount);
                // console.log("balance of recipient: ", erc1155.balanceOf(address(recipient), rewardUnits[i].tokenId));
                erc1155Amounts[rewardUnits[i].tokenId] += rewardUnits[i].totalAmount;
            } else if (rewardUnits[i].tokenType == ITokenBundle.TokenType.ERC721) {
                // console2.log("total amount: ", rewardUnits[i].totalAmount);
                // console.log("balance of recipient: ", erc721.balanceOf(address(recipient)));
                erc721Amount += rewardUnits[i].totalAmount;
            }
            // console2.log("");
        }
    }

    function test_fuzz_state_createPack(uint256 x, uint128 y) public {
        (ITokenBundle.Token[] memory tokensToPack, uint256[] memory rewardUnits) = getTokensToPack(x);
        if (tokensToPack.length == 0) {
            return;
        }

        uint256 packId = pack.nextTokenIdToMint();
        address recipient = address(0x123);
        uint256 totalRewardUnits;
        uint256 nativeTokenPacked;

        for (uint256 i = 0; i < tokensToPack.length; i += 1) {
            totalRewardUnits += rewardUnits[i];
            if (tokensToPack[i].assetContract == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                nativeTokenPacked += tokensToPack[i].totalAmount;
            }
        }
        vm.deal(address(tokenOwner), nativeTokenPacked);
        vm.assume(y > 0 && totalRewardUnits % y == 0);

        vm.prank(address(tokenOwner));
        (, uint256 totalSupply) = pack.createPack{ value: nativeTokenPacked }(
            tokensToPack,
            rewardUnits,
            packUri,
            0,
            y,
            recipient
        );
        console2.log("total supply: ", totalSupply);
        console2.log("total reward units: ", totalRewardUnits);

        assertEq(packId + 1, pack.nextTokenIdToMint());

        (ITokenBundle.Token[] memory packed, ) = pack.getPackContents(packId);
        assertEq(packed.length, tokensToPack.length);
        for (uint256 i = 0; i < packed.length; i += 1) {
            assertEq(packed[i].assetContract, tokensToPack[i].assetContract);
            assertEq(uint256(packed[i].tokenType), uint256(tokensToPack[i].tokenType));
            assertEq(packed[i].tokenId, tokensToPack[i].tokenId);
            assertEq(packed[i].totalAmount, tokensToPack[i].totalAmount);
        }

        assertEq(packUri, pack.uri(packId));
    }

    /*///////////////////////////////////////////////////////////////
                            Scenario/Exploit tests
    //////////////////////////////////////////////////////////////*/
    /**
     *  note: Testing revert condition; token owner calls `createPack` to pack owned tokens.
     */
    function test_revert_createPack_reentrancy() public {
        MaliciousERC20 malERC20 = new MaliciousERC20(payable(address(pack)));
        ITokenBundle.Token[] memory content = new ITokenBundle.Token[](1);
        uint256[] memory rewards = new uint256[](1);

        malERC20.mint(address(tokenOwner), 10 ether);
        content[0] = ITokenBundle.Token({
            assetContract: address(malERC20),
            tokenType: ITokenBundle.TokenType.ERC20,
            tokenId: 0,
            totalAmount: 10 ether
        });
        rewards[0] = 10;

        tokenOwner.setAllowanceERC20(address(malERC20), address(pack), 10 ether);

        address recipient = address(0x123);

        vm.prank(address(deployer));
        pack.grantRole(keccak256("MINTER_ROLE"), address(malERC20));

        vm.startPrank(address(tokenOwner));
        vm.expectRevert("ReentrancyGuard: reentrant call");
        pack.createPack(content, rewards, packUri, 0, 1, recipient);
    }
}

contract MaliciousERC20 is MockERC20, ITokenBundle {
    Pack public pack;

    constructor(address payable _pack) {
        pack = Pack(_pack);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        ITokenBundle.Token[] memory content = new ITokenBundle.Token[](1);
        uint256[] memory rewards = new uint256[](1);

        address recipient = address(0x123);
        pack.createPack(content, rewards, "", 0, 1, recipient);
        return super.transferFrom(from, to, amount);
    }
}
