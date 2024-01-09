// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";
import { BurnToClaimDropERC721 } from "contracts/prebuilts/unaudited/burn-to-claim-drop/BurnToClaimDropERC721.sol";
import { BurnToClaimDrop721Logic, ERC721AUpgradeable, DelayedReveal, LazyMint, Drop, BurnToClaim, PrimarySale, PlatformFee } from "contracts/prebuilts/unaudited/burn-to-claim-drop/extension/BurnToClaimDrop721Logic.sol";
import { PermissionsEnumerableImpl } from "contracts/extension/upgradeable/impl/PermissionsEnumerableImpl.sol";
import { Royalty } from "contracts/extension/upgradeable/Royalty.sol";
import { BatchMintMetadata } from "contracts/extension/upgradeable/BatchMintMetadata.sol";
import { IBurnToClaim } from "contracts/extension/interface/IBurnToClaim.sol";

import "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import { Permissions } from "contracts/extension/Permissions.sol";
import { PermissionsEnumerable } from "contracts/extension/PermissionsEnumerable.sol";
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

contract BurnToClaimDropERC721Test is BaseTest, IExtension {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    BurnToClaimDrop721Logic public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        drop = BurnToClaimDrop721Logic(
            payable(
                address(
                    new TWProxy(
                        dropImpl,
                        abi.encodeCall(
                            BurnToClaimDropERC721.initialize,
                            (
                                deployer,
                                NAME,
                                SYMBOL,
                                CONTRACT_URI,
                                forwarders(),
                                saleRecipient,
                                royaltyRecipient,
                                royaltyBps,
                                platformFeeBps,
                                platformFeeRecipient
                            )
                        )
                    )
                )
            )
        );

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
    }

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](2);

        // Extension: Permissions
        address permissions = address(new PermissionsEnumerableImpl());

        Extension memory extension_permissions;
        extension_permissions.metadata = ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        extension_permissions.functions = new ExtensionFunction[](7);
        extension_permissions.functions[0] = ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );
        extension_permissions.functions[1] = ExtensionFunction(
            Permissions.hasRoleWithSwitch.selector,
            "hasRoleWithSwitch(bytes32,address)"
        );
        extension_permissions.functions[2] = ExtensionFunction(
            Permissions.grantRole.selector,
            "grantRole(bytes32,address)"
        );
        extension_permissions.functions[3] = ExtensionFunction(
            Permissions.renounceRole.selector,
            "renounceRole(bytes32,address)"
        );
        extension_permissions.functions[4] = ExtensionFunction(
            Permissions.revokeRole.selector,
            "revokeRole(bytes32,address)"
        );
        extension_permissions.functions[5] = ExtensionFunction(
            PermissionsEnumerable.getRoleMemberCount.selector,
            "getRoleMemberCount(bytes32)"
        );
        extension_permissions.functions[6] = ExtensionFunction(
            PermissionsEnumerable.getRoleMember.selector,
            "getRoleMember(bytes32,uint256)"
        );

        extensions[0] = extension_permissions;

        address dropLogic = address(new BurnToClaimDrop721Logic());

        Extension memory extension_drop;
        extension_drop.metadata = ExtensionMetadata({
            name: "BurnToClaimDrop721Logic",
            metadataURI: "ipfs://BurnToClaimDrop721Logic",
            implementation: dropLogic
        });

        extension_drop.functions = new ExtensionFunction[](32);
        extension_drop.functions[0] = ExtensionFunction(BurnToClaimDrop721Logic.tokenURI.selector, "tokenURI(uint256)");
        extension_drop.functions[1] = ExtensionFunction(
            BurnToClaimDrop721Logic.lazyMint.selector,
            "lazyMint(uint256,string,bytes)"
        );
        extension_drop.functions[2] = ExtensionFunction(
            BurnToClaimDrop721Logic.reveal.selector,
            "reveal(uint256,bytes)"
        );
        extension_drop.functions[3] = ExtensionFunction(Drop.claimCondition.selector, "claimCondition()");
        extension_drop.functions[4] = ExtensionFunction(
            BatchMintMetadata.getBaseURICount.selector,
            "getBaseURICount()"
        );
        extension_drop.functions[5] = ExtensionFunction(
            Drop.claim.selector,
            "claim(address,uint256,address,uint256,(bytes32[],uint256,uint256,address),bytes)"
        );
        extension_drop.functions[6] = ExtensionFunction(
            Drop.setClaimConditions.selector,
            "setClaimConditions((uint256,uint256,uint256,uint256,bytes32,uint256,address,string)[],bool)"
        );
        extension_drop.functions[7] = ExtensionFunction(
            Drop.getActiveClaimConditionId.selector,
            "getActiveClaimConditionId()"
        );
        extension_drop.functions[8] = ExtensionFunction(
            Drop.getClaimConditionById.selector,
            "getClaimConditionById(uint256)"
        );
        extension_drop.functions[9] = ExtensionFunction(
            Drop.getSupplyClaimedByWallet.selector,
            "getSupplyClaimedByWallet(uint256,address)"
        );
        extension_drop.functions[10] = ExtensionFunction(BurnToClaimDrop721Logic.totalMinted.selector, "totalMinted()");
        extension_drop.functions[11] = ExtensionFunction(
            BurnToClaimDrop721Logic.nextTokenIdToMint.selector,
            "nextTokenIdToMint()"
        );
        extension_drop.functions[12] = ExtensionFunction(
            IERC721Upgradeable.setApprovalForAll.selector,
            "setApprovalForAll(address,bool)"
        );
        extension_drop.functions[13] = ExtensionFunction(
            IERC721Upgradeable.approve.selector,
            "approve(address,uint256)"
        );
        extension_drop.functions[14] = ExtensionFunction(
            IERC721Upgradeable.transferFrom.selector,
            "transferFrom(address,address,uint256)"
        );
        extension_drop.functions[15] = ExtensionFunction(ERC721AUpgradeable.balanceOf.selector, "balanceOf(address)");
        extension_drop.functions[16] = ExtensionFunction(
            DelayedReveal.encryptDecrypt.selector,
            "encryptDecrypt(bytes,bytes)"
        );
        extension_drop.functions[17] = ExtensionFunction(
            BurnToClaimDrop721Logic.supportsInterface.selector,
            "supportsInterface(bytes4)"
        );
        extension_drop.functions[18] = ExtensionFunction(Royalty.royaltyInfo.selector, "royaltyInfo(uint256,uint256)");
        extension_drop.functions[19] = ExtensionFunction(
            Royalty.getRoyaltyInfoForToken.selector,
            "getRoyaltyInfoForToken(uint256)"
        );
        extension_drop.functions[20] = ExtensionFunction(
            Royalty.getDefaultRoyaltyInfo.selector,
            "getDefaultRoyaltyInfo()"
        );
        extension_drop.functions[21] = ExtensionFunction(
            Royalty.setDefaultRoyaltyInfo.selector,
            "setDefaultRoyaltyInfo(address,uint256)"
        );
        extension_drop.functions[22] = ExtensionFunction(
            Royalty.setRoyaltyInfoForToken.selector,
            "setRoyaltyInfoForToken(uint256,address,uint256)"
        );
        extension_drop.functions[23] = ExtensionFunction(IERC721.ownerOf.selector, "ownerOf(uint256)");
        extension_drop.functions[24] = ExtensionFunction(IERC1155.balanceOf.selector, "balanceOf(address,uint256)");
        extension_drop.functions[25] = ExtensionFunction(
            BurnToClaim.setBurnToClaimInfo.selector,
            "setBurnToClaimInfo((address,uint8,uint256,uint256,address))"
        );
        extension_drop.functions[26] = ExtensionFunction(
            BurnToClaim.getBurnToClaimInfo.selector,
            "getBurnToClaimInfo()"
        );
        extension_drop.functions[27] = ExtensionFunction(
            BurnToClaim.verifyBurnToClaim.selector,
            "verifyBurnToClaim(address,uint256,uint256)"
        );
        extension_drop.functions[28] = ExtensionFunction(
            BurnToClaimDrop721Logic.burnAndClaim.selector,
            "burnAndClaim(uint256,uint256)"
        );
        extension_drop.functions[29] = ExtensionFunction(
            BurnToClaimDrop721Logic.nextTokenIdToClaim.selector,
            "nextTokenIdToClaim()"
        );
        extension_drop.functions[30] = ExtensionFunction(
            PrimarySale.setPrimarySaleRecipient.selector,
            "setPrimarySaleRecipient(address)"
        );
        extension_drop.functions[31] = ExtensionFunction(
            PlatformFee.setPlatformFeeInfo.selector,
            "setPlatformFeeInfo(address,uint256)"
        );

        extensions[1] = extension_drop;
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_revert_nonHolder_renounceRole() public {
        address caller = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(caller);
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                Strings.toHexString(uint160(caller), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );

        Permissions(address(drop)).renounceRole(role, caller);
    }

    /**
     *  note: Tests whether contract reverts when a role admin revokes a role for a non-holder.
     */
    function test_revert_revokeRoleForNonHolder() public {
        address target = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(deployer);
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                Strings.toHexString(uint160(target), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );

        Permissions(address(drop)).revokeRole(role, target);
    }

    /**
     *  @dev Tests whether contract reverts when a role is granted to an existent role holder.
     */
    function test_revert_grant_role_to_account_with_role() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);

        Permissions(address(drop)).grantRole(role, receiver);

        vm.expectRevert("Can only grant to non holders");
        Permissions(address(drop)).grantRole(role, receiver);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_grant_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        // check if admin and address(0) have transfer role in the beginning
        bool checkAddressZero = Permissions(address(drop)).hasRole(role, address(0));
        bool checkAdmin = Permissions(address(drop)).hasRole(role, deployer);
        assertTrue(checkAddressZero);
        assertTrue(checkAdmin);

        // check if transfer role can be granted to a non-holder
        address receiver = getActor(0);
        vm.startPrank(deployer);
        Permissions(address(drop)).grantRole(role, receiver);

        // expect revert when granting to a holder
        vm.expectRevert("Can only grant to non holders");
        Permissions(address(drop)).grantRole(role, receiver);

        // check if receiver has transfer role
        bool checkReceiver = Permissions(address(drop)).hasRole(role, receiver);
        assertTrue(checkReceiver);

        // check if role is correctly revoked
        Permissions(address(drop)).revokeRole(role, receiver);
        checkReceiver = Permissions(address(drop)).hasRole(role, receiver);
        assertFalse(checkReceiver);
        Permissions(address(drop)).revokeRole(role, address(0));
        checkAddressZero = Permissions(address(drop)).hasRole(role, address(0));
        assertFalse(checkAddressZero);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_getRoleMember_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        uint256 roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        assertEq(roleMemberCount, 2);

        address roleMember = PermissionsEnumerable(address(drop)).getRoleMember(role, 1);
        assertEq(roleMember, address(0));

        vm.startPrank(deployer);
        Permissions(address(drop)).grantRole(role, address(2));
        Permissions(address(drop)).grantRole(role, address(3));
        Permissions(address(drop)).grantRole(role, address(4));

        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");

        Permissions(address(drop)).revokeRole(role, address(2));
        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");

        Permissions(address(drop)).revokeRole(role, address(0));
        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");

        Permissions(address(drop)).grantRole(role, address(5));
        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");

        Permissions(address(drop)).grantRole(role, address(0));
        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");

        Permissions(address(drop)).grantRole(role, address(6));
        roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(PermissionsEnumerable(address(drop)).getRoleMember(role, i));
        }
        console.log("");
    }

    /**
     *  note: Testing transfer of tokens when transfer-role is restricted
     */
    function test_claim_transferRole() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 1, address(0), 0, alp, "");

        // revoke transfer role from address(0)
        vm.prank(deployer);
        Permissions(address(drop)).revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.startPrank(receiver);
        vm.expectRevert("!Transfer-Role");
        drop.transferFrom(receiver, address(123), 0);
    }

    /**
     *  @dev Tests whether role member count is incremented correctly.
     */
    function test_member_count_incremented_properly_when_role_granted() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);
        uint256 roleMemberCount = PermissionsEnumerable(address(drop)).getRoleMemberCount(role);

        assertEq(roleMemberCount, 0);

        Permissions(address(drop)).grantRole(role, receiver);

        assertEq(PermissionsEnumerable(address(drop)).getRoleMemberCount(role), 1);

        vm.stopPrank();
    }

    function test_claimCondition_with_startTimestamp() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].startTimestamp = 100;
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.warp(99);
        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("!CONDITION.");
        drop.claim(receiver, 1, address(0), 0, alp, "");

        vm.warp(100);
        vm.prank(getActor(4), getActor(4));
        drop.claim(receiver, 1, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                    Primary sale and Platform fee tests
    //////////////////////////////////////////////////////////////*/

    /// note: Test whether transaction reverts when adding address(0) as primary sale recipient at deploy time
    function test_revert_deploy_emptyPrimarySaleRecipient() public {
        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        vm.expectRevert("Invalid recipient");
        drop = BurnToClaimDrop721Logic(
            payable(
                address(
                    new TWProxy(
                        dropImpl,
                        abi.encodeCall(
                            BurnToClaimDropERC721.initialize,
                            (
                                deployer,
                                NAME,
                                SYMBOL,
                                CONTRACT_URI,
                                forwarders(),
                                address(0),
                                royaltyRecipient,
                                royaltyBps,
                                platformFeeBps,
                                platformFeeRecipient
                            )
                        )
                    )
                )
            )
        );
    }

    /// note: Test whether transaction reverts when adding address(0) as primary sale recipient
    function test_revert_emptyPrimarySaleRecipient() public {
        vm.prank(deployer);
        vm.expectRevert("Invalid recipient");
        drop.setPrimarySaleRecipient(address(0));
    }

    /// note: Test whether transaction reverts when adding address(0) as platform fee recipient at deploy time
    function test_revert_deploy_emptyPlatformFeeRecipient() public {
        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address dropImpl = address(new BurnToClaimDropERC721(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        vm.expectRevert("Invalid recipient");
        drop = BurnToClaimDrop721Logic(
            payable(
                address(
                    new TWProxy(
                        dropImpl,
                        abi.encodeCall(
                            BurnToClaimDropERC721.initialize,
                            (
                                deployer,
                                NAME,
                                SYMBOL,
                                CONTRACT_URI,
                                forwarders(),
                                saleRecipient,
                                royaltyRecipient,
                                royaltyBps,
                                platformFeeBps,
                                address(0)
                            )
                        )
                    )
                )
            )
        );
    }

    /// note: Test whether transaction reverts when adding address(0) as platform fee recipient
    function test_revert_emptyPlatformFeeRecipient() public {
        vm.prank(deployer);
        vm.expectRevert("Invalid recipient");
        drop.setPlatformFeeInfo(address(0), 100);
    }

    /*///////////////////////////////////////////////////////////////
                            Lazy Mint Tests
    //////////////////////////////////////////////////////////////*/

    /*
     *  note: Testing state changes; lazy mint a batch of tokens with no encrypted base URI.
     */
    function test_state_lazyMint_noEncryptedURI() public {
        uint256 amountToLazyMint = 100;
        string memory baseURI = "ipfs://";

        uint256 nextTokenIdToMintBefore = drop.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = drop.lazyMint(amountToLazyMint, baseURI, emptyEncodedBytes);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, drop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = drop.tokenURI(i);
            console.log(uri);
            assertEq(uri, string(abi.encodePacked(baseURI, i.toString())));
        }

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; lazy mint a batch of tokens with encrypted base URI.
     */
    function test_state_lazyMint_withEncryptedURI() public {
        uint256 amountToLazyMint = 100;
        string memory baseURI = "ipfs://";
        bytes memory encryptedBaseURI = "encryptedBaseURI://";
        bytes32 provenanceHash = bytes32("whatever");

        uint256 nextTokenIdToMintBefore = drop.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = drop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, drop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = drop.tokenURI(i);
            console.log(uri);
            assertEq(uri, string(abi.encodePacked(baseURI, "0")));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls lazyMint function.
     */
    function test_revert_lazyMint_MINTER_ROLE() public {
        vm.expectRevert("Not authorized");
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    /*
     *  note: Testing revert condition; calling tokenURI for invalid batch id.
     */
    function test_revert_lazyMint_URIForNonLazyMintedToken() public {
        vm.startPrank(deployer);

        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.expectRevert("Invalid tokenId");
        drop.tokenURI(100);

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; tokens lazy minted.
     */
    function test_event_lazyMint_TokensLazyMinted() public {
        vm.startPrank(deployer);

        vm.expectEmit(true, false, false, true);
        emit TokensLazyMinted(0, 99, "ipfs://", emptyEncodedBytes);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing state changes; lazy mint a batch of tokens with no encrypted base URI.
     */
    function test_fuzz_lazyMint_noEncryptedURI(uint256 x) public {
        vm.assume(x > 0);

        uint256 amountToLazyMint = x;
        string memory baseURI = "ipfs://";

        uint256 nextTokenIdToMintBefore = drop.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = drop.lazyMint(amountToLazyMint, baseURI, emptyEncodedBytes);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, drop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = drop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(0).toString())));

        uri = drop.tokenURI(x - 1);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(x - 1).toString())));

        /**
         *  note: this loop takes too long to run with fuzz tests.
         */
        // for(uint256 i = 0; i < amountToLazyMint; i += 1) {
        //     string memory uri = drop.tokenURI(i);
        //     console.log(uri);
        //     assertEq(uri, string(abi.encodePacked(baseURI, i.toString())));
        // }

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing state changes; lazy mint a batch of tokens with encrypted base URI.
     */
    function test_fuzz_lazyMint_withEncryptedURI(uint256 x) public {
        vm.assume(x > 0);

        uint256 amountToLazyMint = x;
        string memory baseURI = "ipfs://";
        bytes memory encryptedBaseURI = "encryptedBaseURI://";
        bytes32 provenanceHash = bytes32("whatever");

        uint256 nextTokenIdToMintBefore = drop.nextTokenIdToMint();

        vm.startPrank(deployer);
        uint256 batchId = drop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, drop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = drop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, "0")));

        uri = drop.tokenURI(x - 1);
        assertEq(uri, string(abi.encodePacked(baseURI, "0")));

        /**
         *  note: this loop takes too long to run with fuzz tests.
         */
        // for(uint256 i = 0; i < amountToLazyMint; i += 1) {
        //     string memory uri = drop.tokenURI(1);
        //     assertEq(uri, string(abi.encodePacked(baseURI, "0")));
        // }

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing; a batch of tokens, and nextTokenIdToMint
     */
    function test_fuzz_lazyMint_batchMintAndNextTokenIdToMint(uint256 x) public {
        vm.assume(x > 0);
        vm.startPrank(deployer);

        if (x == 0) {
            vm.expectRevert("Zero amount");
        }
        drop.lazyMint(x, "ipfs://", emptyEncodedBytes);

        uint256 slot = stdstore.target(address(drop)).sig("nextTokenIdToMint()").find();
        bytes32 loc = bytes32(slot);
        uint256 nextTokenIdToMint = uint256(vm.load(address(drop), loc));

        assertEq(nextTokenIdToMint, x);
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Delayed Reveal Tests
    //////////////////////////////////////////////////////////////*/

    /*
     *  note: Testing state changes; URI revealed for a batch of tokens.
     */
    function test_state_reveal() public {
        vm.startPrank(deployer);

        bytes memory key = "key";
        uint256 amountToLazyMint = 100;
        bytes memory secretURI = "ipfs://";
        string memory placeholderURI = "abcd://";
        bytes memory encryptedURI = drop.encryptDecrypt(secretURI, key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        drop.lazyMint(amountToLazyMint, placeholderURI, abi.encode(encryptedURI, provenanceHash));

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = drop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(placeholderURI, "0")));
        }

        string memory revealedURI = drop.reveal(0, key);
        assertEq(revealedURI, string(secretURI));

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = drop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(secretURI, i.toString())));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls reveal function.
     */
    function test_revert_reveal_MINTER_ROLE() public {
        bytes memory key = "key";
        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        vm.prank(deployer);
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        vm.prank(deployer);
        drop.reveal(0, "key");

        vm.expectRevert("not minter.");
        drop.reveal(0, "key");
    }

    /*
     *  note: Testing revert condition; trying to reveal URI for non-existent batch.
     */
    function test_revert_reveal_revealingNonExistentBatch() public {
        vm.startPrank(deployer);

        bytes memory key = "key";
        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        drop.reveal(0, "key");

        console.log(drop.getBaseURICount());

        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        vm.expectRevert("Invalid index");
        drop.reveal(2, "key");

        vm.stopPrank();
    }

    /*
     *  note: Testing revert condition; already revealed URI.
     */
    function test_revert_delayedReveal_alreadyRevealed() public {
        vm.startPrank(deployer);

        bytes memory key = "key";
        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        drop.reveal(0, "key");

        vm.expectRevert("Nothing to reveal");
        drop.reveal(0, "key");

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; revealing URI with an incorrect key.
     */
    function testFail_reveal_incorrectKey() public {
        vm.startPrank(deployer);

        bytes memory key = "key";
        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        string memory revealedURI = drop.reveal(0, "keyy");
        assertEq(revealedURI, "ipfs://");

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; TokenURIRevealed.
     */
    function test_event_reveal_TokenURIRevealed() public {
        vm.startPrank(deployer);

        bytes memory key = "key";
        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        vm.expectEmit(true, false, false, true);
        emit TokenURIRevealed(0, "ipfs://");
        drop.reveal(0, "key");

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; not enough minted tokens.
     */
    function test_revert_claimCondition_notEnoughMintedTokens() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.expectRevert("!Tokens");
        vm.prank(getActor(6), getActor(6));
        drop.claim(receiver, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing revert condition; exceed max claimable supply.
     */
    function test_revert_claimCondition_exceedMaxClaimableSupply() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        drop.lazyMint(200, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert("!MaxSupply");
        vm.prank(getActor(6), getActor(6));
        drop.claim(receiver, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        drop.claim(receiver, 0, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        drop.claim(receiver, 101, address(0), 0, alp, "");

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        drop.claim(receiver, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price set to 0
     */
    function test_state_claim_allowlisted_SetQuantityZeroPrice() public {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "0";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 100, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), 100);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price set to non-zero value
     */
    function test_state_claim_allowlisted_SetQuantityPrice() public {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "5";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        vm.expectRevert("!PriceOrCurrency");
        drop.claim(receiver, 100, address(erc20), 0, alp, "");

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 100, address(erc20), 5, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), 100);
        assertEq(erc20.balanceOf(receiver), 10000 - 500);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price not set; should default to general price and currency
     */
    function test_state_claim_allowlisted_SetQuantityDefaultPrice() public {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = Strings.toString(type(uint256).max); // this implies that general price is applicable
        inputs[4] = "0x0000000000000000000000000000000000000000";

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = type(uint256).max;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 100, address(erc20), 10, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), 100);
        assertEq(erc20.balanceOf(receiver), 10000 - 1000);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to 0 => should default to general limit
     *          - allowlist price set to some value different than general price
     */
    function test_state_claim_allowlisted_DefaultQuantitySomePrice() public {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "0"; // this implies that general limit is applicable
        inputs[3] = "5";
        inputs[4] = "0x0000000000000000000000000000000000000000"; // general currency will be applicable

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 0;
        alp.pricePerToken = 5;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        bytes memory errorQty = "!Qty";
        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        drop.claim(receiver, 100, address(erc20), 5, alp, ""); // trying to claim more than general limit

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 10, address(erc20), 5, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), 10);
        assertEq(erc20.balanceOf(receiver), 10000 - 50);
    }

    function test_fuzz_claim_merkleProof(uint256 x) public {
        vm.assume(x > 10 && x < 500);
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = Strings.toString(x);
        inputs[3] = "0";
        inputs[4] = "0x0000000000000000000000000000000000000000";

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        // bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        drop.lazyMint(2 * x, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, x - 5, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), x - 5);

        bytes memory errorQty = "!Qty";

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        drop.claim(receiver, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        drop.claim(receiver, 5, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(drop.getActiveClaimConditionId(), receiver), x);

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        drop.claim(receiver, 5, address(0), 0, alp, ""); // quantity limit already claimed
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        BurnToClaimDrop721Logic.AllowlistProof memory alp;
        alp.proof = proofs;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 100, address(0), 0, alp, "");

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        drop.claim(receiver, 100, address(0), 0, alp, "");

        vm.prank(deployer);
        drop.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, 100, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            setClaimConditions
    //////////////////////////////////////////////////////////////*/

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 currentStartId = 0;
        uint256 count = 0;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, false);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        drop.setClaimConditions(conditions, true);
        (currentStartId, count) = drop.claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 activeConditionId = 0;

        BurnToClaimDrop721Logic.ClaimCondition[] memory conditions = new BurnToClaimDrop721Logic.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerWallet = 12;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerWallet = 22;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerWallet = 32;
        drop.setClaimConditions(conditions, false);

        vm.expectRevert("!CONDITION.");
        drop.getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 0);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 10);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 12);

        vm.warp(20);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 1);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 20);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 22);

        vm.warp(30);
        activeConditionId = drop.getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        assertEq(drop.getClaimConditionById(activeConditionId).startTimestamp, 30);
        assertEq(drop.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        assertEq(drop.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 32);

        vm.warp(40);
        assertEq(drop.getActiveClaimConditionId(), 2);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_delayedReveal_withNewLazyMintedEmptyBatch() public {
        vm.startPrank(deployer);

        bytes memory encryptedURI = drop.encryptDecrypt("ipfs://", "key");
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", "key", block.chainid));
        drop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        drop.reveal(0, "key");

        string memory uri = drop.tokenURI(1);
        assertEq(uri, string(abi.encodePacked("ipfs://", "1")));

        bytes memory newEncryptedURI = drop.encryptDecrypt("ipfs://secret", "key");
        vm.expectRevert("0 amt");
        drop.lazyMint(0, "", abi.encode(newEncryptedURI, provenanceHash));

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                            Burn To Claim
    //////////////////////////////////////////////////////////////*/

    function test_state_burnAndClaim_1155Origin_zeroMintPrice() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc1155);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC1155;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 0;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc1155 to a claimer
        address claimer = getActor(0);
        erc1155.mint(claimer, 0, 10);
        assertEq(erc1155.balanceOf(claimer, 0), 10);
        vm.prank(claimer);
        erc1155.setApprovalForAll(address(drop), true);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim(0, 10);

        // check state
        assertEq(erc1155.balanceOf(claimer, 0), 0);
        assertEq(drop.balanceOf(claimer), 10);
        assertEq(drop.nextTokenIdToClaim(), 10);
    }

    function test_state_burnAndClaim_1155Origin_nonZeroMintPrice() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc1155);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC1155;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 1;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc1155 to a claimer
        address claimer = getActor(0);
        erc1155.mint(claimer, 0, 10);
        assertEq(erc1155.balanceOf(claimer, 0), 10);
        vm.prank(claimer);
        erc1155.setApprovalForAll(address(drop), true);

        // mint erc20 to claimer, to pay claim price
        erc20.mint(claimer, 100);
        vm.prank(claimer);
        erc20.approve(address(drop), type(uint256).max);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim(0, 10);

        // check state
        assertEq(erc1155.balanceOf(claimer, 0), 0);
        assertEq(erc20.balanceOf(claimer), 90);
        assertEq(erc20.balanceOf(saleRecipient), 10);
        assertEq(drop.balanceOf(claimer), 10);
        assertEq(drop.nextTokenIdToClaim(), 10);
    }

    function test_state_burnAndClaim_1155Origin_nonZeroMintPrice_nativeToken() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc1155);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC1155;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 1;
        burnToClaimInfo.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc1155 to a claimer
        address claimer = getActor(0);
        erc1155.mint(claimer, 0, 10);
        assertEq(erc1155.balanceOf(claimer, 0), 10);
        vm.prank(claimer);
        erc1155.setApprovalForAll(address(drop), true);

        // deal ether to claimer, to pay claim price
        vm.deal(claimer, 100);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim{ value: 10 }(0, 10);

        // check state
        assertEq(erc1155.balanceOf(claimer, 0), 0);
        assertEq(claimer.balance, 90);
        assertEq(saleRecipient.balance, 10);
        assertEq(drop.balanceOf(claimer), 10);
        assertEq(drop.nextTokenIdToClaim(), 10);
    }

    function test_state_burnAndClaim_721Origin_zeroMintPrice() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc721);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC721;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 0;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc721 to a claimer
        address claimer = getActor(0);
        erc721.mint(claimer, 10);
        assertEq(erc721.balanceOf(claimer), 10);
        vm.prank(claimer);
        erc721.setApprovalForAll(address(drop), true);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim(0, 1);

        // check state
        assertEq(erc721.balanceOf(claimer), 9);
        assertEq(drop.balanceOf(claimer), 1);
        assertEq(drop.nextTokenIdToClaim(), 1);

        vm.expectRevert("ERC721: invalid token ID"); // because the token doesn't exist anymore
        erc721.ownerOf(0);
    }

    function test_state_burnAndClaim_721Origin_nonZeroMintPrice() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc721);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC721;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 1;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc721 to a claimer
        address claimer = getActor(0);
        erc721.mint(claimer, 10);
        assertEq(erc721.balanceOf(claimer), 10);
        vm.prank(claimer);
        erc721.setApprovalForAll(address(drop), true);

        // mint erc20 to claimer, to pay claim price
        erc20.mint(claimer, 100);
        vm.prank(claimer);
        erc20.approve(address(drop), type(uint256).max);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim(0, 1);

        // check state
        assertEq(erc721.balanceOf(claimer), 9);
        assertEq(drop.balanceOf(claimer), 1);
        assertEq(drop.nextTokenIdToClaim(), 1);
        assertEq(erc20.balanceOf(claimer), 99);
        assertEq(erc20.balanceOf(saleRecipient), 1);

        vm.expectRevert("ERC721: invalid token ID"); // because the token doesn't exist anymore
        erc721.ownerOf(0);
    }

    function test_state_burnAndClaim_721Origin_nonZeroMintPrice_nativeToken() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc721);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC721;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 1;
        burnToClaimInfo.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // check details correctly saved
        BurnToClaimDrop721Logic.BurnToClaimInfo memory savedInfo = drop.getBurnToClaimInfo();
        assertEq(savedInfo.originContractAddress, burnToClaimInfo.originContractAddress);
        assertTrue(savedInfo.tokenType == burnToClaimInfo.tokenType);
        assertEq(savedInfo.tokenId, burnToClaimInfo.tokenId);
        assertEq(savedInfo.mintPriceForNewToken, burnToClaimInfo.mintPriceForNewToken);
        assertEq(savedInfo.currency, burnToClaimInfo.currency);

        // mint some erc721 to a claimer
        address claimer = getActor(0);
        erc721.mint(claimer, 10);
        assertEq(erc721.balanceOf(claimer), 10);
        vm.prank(claimer);
        erc721.setApprovalForAll(address(drop), true);

        // deal ether to claimer, to pay claim price
        vm.deal(claimer, 100);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        drop.burnAndClaim{ value: 1 }(0, 1);

        // check state
        assertEq(erc721.balanceOf(claimer), 9);
        assertEq(drop.balanceOf(claimer), 1);
        assertEq(drop.nextTokenIdToClaim(), 1);
        assertEq(claimer.balance, 99);
        assertEq(saleRecipient.balance, 1);

        vm.expectRevert("ERC721: invalid token ID"); // because the token doesn't exist anymore
        erc721.ownerOf(0);
    }

    function test_revert_burnAndClaim_originNotSet() public {
        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.expectRevert();
        drop.burnAndClaim(0, 1);
    }

    function test_revert_burnAndClaim_noLazyMintedTokens() public {
        // burn and claim
        vm.expectRevert("!Tokens");
        drop.burnAndClaim(0, 1);
    }

    function test_revert_burnAndClaim_invalidTokenId() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc1155);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC1155;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 0;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // mint some erc1155 to a claimer
        address claimer = getActor(0);
        erc1155.mint(claimer, 0, 10);
        assertEq(erc1155.balanceOf(claimer, 0), 10);
        vm.prank(claimer);
        erc1155.setApprovalForAll(address(drop), true);

        // burn and claim
        vm.prank(claimer);
        vm.expectRevert("Invalid token Id");
        drop.burnAndClaim(1, 1);
    }

    function test_revert_burnAndClaim_notEnoughBalance() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc1155);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC1155;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 0;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // mint some erc1155 to a claimer
        address claimer = getActor(0);
        erc1155.mint(claimer, 0, 10);
        assertEq(erc1155.balanceOf(claimer, 0), 10);
        vm.prank(claimer);
        erc1155.setApprovalForAll(address(drop), true);

        // burn and claim
        vm.prank(claimer);
        vm.expectRevert("!Balance");
        drop.burnAndClaim(0, 11);
    }

    function test_revert_burnAndClaim_notOwnerOfToken() public {
        IBurnToClaim.BurnToClaimInfo memory burnToClaimInfo;

        burnToClaimInfo.originContractAddress = address(erc721);
        burnToClaimInfo.tokenType = IBurnToClaim.TokenType.ERC721;
        burnToClaimInfo.tokenId = 0;
        burnToClaimInfo.mintPriceForNewToken = 1;
        burnToClaimInfo.currency = address(erc20);

        // set origin contract details for burn and claim
        vm.prank(deployer);
        drop.setBurnToClaimInfo(burnToClaimInfo);

        // mint some erc721 to a claimer
        address claimer = getActor(0);
        erc721.mint(claimer, 10);
        assertEq(erc721.balanceOf(claimer), 10);
        vm.prank(claimer);
        erc721.setApprovalForAll(address(drop), true);

        // mint erc721 to another address
        erc721.mint(address(0x567), 5);

        // lazy mint tokens
        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        // burn and claim
        vm.prank(claimer);
        vm.expectRevert("!Owner");
        drop.burnAndClaim(11, 1);
    }

    /*///////////////////////////////////////////////////////////////
                    Extension Role and Upgradeability
    //////////////////////////////////////////////////////////////*/

    // function test_addExtension() public {
    //     address permissionsNew = address(new PermissionsEnumerableImpl());

    //     Extension memory extension_permissions_new;
    //     extension_permissions_new.metadata = ExtensionMetadata({
    //         name: "PermissionsNew",
    //         metadataURI: "ipfs://PermissionsNew",
    //         implementation: permissionsNew
    //     });

    //     extension_permissions_new.functions = new ExtensionFunction[](4);
    //     extension_permissions_new.functions[0] = ExtensionFunction(
    //         Permissions.hasRole.selector,
    //         "hasRole(bytes32,address)"
    //     );
    //     extension_permissions_new.functions[1] = ExtensionFunction(
    //         Permissions.hasRoleWithSwitch.selector,
    //         "hasRoleWithSwitch(bytes32,address)"
    //     );
    //     extension_permissions_new.functions[2] = ExtensionFunction(
    //         Permissions.grantRole.selector,
    //         "grantRole(bytes32,address)"
    //     );
    //     extension_permissions_new.functions[3] = ExtensionFunction(
    //         PermissionsEnumerable.getRoleMemberCount.selector,
    //         "getRoleMemberCount(bytes32)"
    //     );

    //     // cast drop to router type
    //     BurnToClaimDropERC721 dropRouter = BurnToClaimDropERC721(payable(address(drop)));

    //     vm.prank(deployer);
    //     dropRouter.addExtension(extension_permissions_new);

    //     // assertEq(
    //     //     dropRouter.getExtensionForFunction(PermissionsEnumerable.getRoleMemberCount.selector).name,
    //     //     "PermissionsNew"
    //     // );

    //     // assertEq(
    //     //     dropRouter.getExtensionForFunction(PermissionsEnumerable.getRoleMemberCount.selector).implementation,
    //     //     permissionsNew
    //     // );
    // }

    function test_revert_addExtension_NotAuthorized() public {
        Extension memory extension_permissions_new;

        // cast drop to router type
        BurnToClaimDropERC721 dropRouter = BurnToClaimDropERC721(payable(address(drop)));

        vm.prank(address(0x123));
        vm.expectRevert("ExtensionManager: unauthorized.");
        dropRouter.addExtension(extension_permissions_new);
    }

    function test_revert_addExtension_deployerRenounceExtensionRole() public {
        Extension memory extension_permissions_new;

        // cast drop to router type
        BurnToClaimDropERC721 dropRouter = BurnToClaimDropERC721(payable(address(drop)));

        vm.prank(deployer);
        Permissions(address(drop)).renounceRole(keccak256("EXTENSION_ROLE"), deployer);

        vm.prank(deployer);
        vm.expectRevert("ExtensionManager: unauthorized.");
        dropRouter.addExtension(extension_permissions_new);

        vm.startPrank(deployer);
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                Strings.toHexString(uint160(deployer), 20),
                " is missing role ",
                Strings.toHexString(uint256(keccak256("EXTENSION_ROLE")), 32)
            )
        );
        Permissions(address(drop)).grantRole(keccak256("EXTENSION_ROLE"), address(0x12345));
        vm.stopPrank();
    }
}
