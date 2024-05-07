// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.sol";

import { TieredDrop } from "contracts/prebuilts/tiered-drop/TieredDrop.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

contract TieredDropTest is BaseTest {
    using Strings for uint256;

    TieredDrop public tieredDrop;

    address internal dropAdmin;
    address internal claimer;

    // Signature params
    address internal deployerSigner;
    bytes32 internal typehashGenericRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    // Lazy mint variables
    uint256 internal quantityTier1 = 10;
    string internal tier1 = "tier1";
    string internal baseURITier1 = "baseURI1/";
    string internal placeholderURITier1 = "placeholderURI1/";
    bytes internal keyTier1 = "tier1_key";

    uint256 internal quantityTier2 = 20;
    string internal tier2 = "tier2";
    string internal baseURITier2 = "baseURI2/";
    string internal placeholderURITier2 = "placeholderURI2/";
    bytes internal keyTier2 = "tier2_key";

    uint256 internal quantityTier3 = 30;
    string internal tier3 = "tier3";
    string internal baseURITier3 = "baseURI3/";
    string internal placeholderURITier3 = "placeholderURI3/";
    bytes internal keyTier3 = "tier3_key";

    function setUp() public virtual override {
        super.setUp();

        dropAdmin = getActor(1);
        claimer = getActor(2);

        // Deploy implementation.
        address tieredDropImpl = address(new TieredDrop());

        // Deploy proxy pointing to implementaion.
        vm.prank(dropAdmin);
        tieredDrop = TieredDrop(
            address(
                new TWProxy(
                    tieredDropImpl,
                    abi.encodeCall(
                        TieredDrop.initialize,
                        (dropAdmin, "Tiered Drop", "TD", "ipfs://", new address[](0), dropAdmin, dropAdmin, 0)
                    )
                )
            )
        );

        // ====== signature params

        deployerSigner = signer;
        vm.prank(dropAdmin);
        tieredDrop.grantRole(keccak256("MINTER_ROLE"), deployerSigner);

        typehashGenericRequest = keccak256(
            "GenericRequest(uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid,bytes data)"
        );
        nameHash = keccak256(bytes("SignatureAction"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tieredDrop))
        );

        // ======
    }

    TieredDrop.GenericRequest internal claimRequest;
    bytes internal claimSignature;

    uint256 internal nonce;

    function _setupClaimSignature(string[] memory _orderedTiers, uint256 _totalQuantity) internal {
        claimRequest.validityStartTimestamp = 1000;
        claimRequest.validityEndTimestamp = 2000;
        claimRequest.uid = keccak256(abi.encodePacked(nonce));
        nonce += 1;
        claimRequest.data = abi.encode(
            _orderedTiers,
            claimer,
            address(0),
            0,
            dropAdmin,
            _totalQuantity,
            0,
            NATIVE_TOKEN
        );

        bytes memory encodedRequest = abi.encode(
            typehashGenericRequest,
            claimRequest.validityStartTimestamp,
            claimRequest.validityEndTimestamp,
            claimRequest.uid,
            keccak256(bytes(claimRequest.data))
        );

        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        claimSignature = abi.encodePacked(r, s, v);
    }

    ////////////////////////////////////////////////
    //                                            //
    //          lazyMintWithTier tests            //
    //                                            //
    ////////////////////////////////////////////////

    // function test_state_lazyMintWithTier() public {
    //     // Lazy mint tokens: 3 different tiers
    //     vm.startPrank(dropAdmin);

    //     // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
    //     // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
    //     // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

    //     vm.stopPrank();

    //     TieredDrop.TierMetadata[] memory metadataForAllTiers = tieredDrop.getMetadataForAllTiers();
    //     (TieredDrop.TokenRange[] memory tokens_1, string[] memory baseURIs_1) = (
    //         metadataForAllTiers[0].ranges,
    //         metadataForAllTiers[0].baseURIs
    //     );
    //     (TieredDrop.TokenRange[] memory tokens_2, string[] memory baseURIs_2) = (
    //         metadataForAllTiers[1].ranges,
    //         metadataForAllTiers[1].baseURIs
    //     );
    //     (TieredDrop.TokenRange[] memory tokens_3, string[] memory baseURIs_3) = (
    //         metadataForAllTiers[2].ranges,
    //         metadataForAllTiers[2].baseURIs
    //     );

    //     uint256 cumulativeStart = 0;

    //     TieredDrop.TokenRange memory range = tokens_1[0];
    //     string memory baseURI = baseURIs_1[0];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier1);
    //     assertEq(baseURI, baseURITier1);

    //     cumulativeStart += quantityTier1;

    //     range = tokens_2[0];
    //     baseURI = baseURIs_2[0];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier2);
    //     assertEq(baseURI, baseURITier2);

    //     cumulativeStart += quantityTier2;

    //     range = tokens_3[0];
    //     baseURI = baseURIs_3[0];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier3);
    //     assertEq(baseURI, baseURITier3);
    // }

    // function test_state_lazyMintWithTier_sameTier() public {
    //     // Lazy mint tokens: 3 different tiers
    //     vm.startPrank(dropAdmin);

    //     // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
    //     // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
    //     // Tier 1 Again: tokenIds assigned 30 -> 60 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier3, baseURITier3, tier1, "");

    //     TieredDrop.TierMetadata[] memory metadataForAllTiers = tieredDrop.getMetadataForAllTiers();
    //     (TieredDrop.TokenRange[] memory tokens_1, string[] memory baseURIs_1) = (
    //         metadataForAllTiers[0].ranges,
    //         metadataForAllTiers[0].baseURIs
    //     );
    //     (TieredDrop.TokenRange[] memory tokens_2, string[] memory baseURIs_2) = (
    //         metadataForAllTiers[1].ranges,
    //         metadataForAllTiers[1].baseURIs
    //     );

    //     vm.stopPrank();

    //     uint256 cumulativeStart = 0;

    //     TieredDrop.TokenRange memory range = tokens_1[0];
    //     string memory baseURI = baseURIs_1[0];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier1);
    //     assertEq(baseURI, baseURITier1);

    //     cumulativeStart += quantityTier1;

    //     range = tokens_2[0];
    //     baseURI = baseURIs_2[0];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier2);
    //     assertEq(baseURI, baseURITier2);

    //     cumulativeStart += quantityTier2;

    //     range = tokens_1[1];
    //     baseURI = baseURIs_1[1];

    //     assertEq(range.startIdInclusive, cumulativeStart);
    //     assertEq(range.endIdNonInclusive, cumulativeStart + quantityTier3);
    //     assertEq(baseURI, baseURITier3);
    // }

    function test_revert_lazyMintWithTier_notMinterRole() public {
        vm.expectRevert("Not authorized");
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
    }

    function test_revert_lazyMintWithTier_mintingZeroAmount() public {
        vm.prank(dropAdmin);
        vm.expectRevert("0 amt");
        tieredDrop.lazyMint(0, baseURITier1, tier1, "");
    }

    ////////////////////////////////////////////////
    //                                            //
    //        claimWithSignature tests            //
    //                                            //
    ////////////////////////////////////////////////

    function test_state_claimWithSignature() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);

        /**
         *  Check token URIs for tokens of tiers:
         *      - Tier 2: token IDs 0 -> 19 mapped one-to-one to metadata IDs 10 -> 29
         *      - Tier 1: token IDs 20 -> 24 mapped one-to-one to metadata IDs 0 -> 4
         */

        uint256 tier2Id = 10;
        uint256 tier1Id = 0;

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            if (i < 20) {
                assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(baseURITier2, tier2Id.toString())));
                tier2Id += 1;
            } else {
                assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(baseURITier1, tier1Id.toString())));
                tier1Id += 1;
            }
        }
    }

    function test_revert_claimWithSignature_invalidEncoding() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        // Create data with invalid encoding.
        claimRequest.data = abi.encode(1, "");
        _setupClaimSignature(tiers, claimQuantity);

        claimRequest.data = abi.encode(1, "");

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        vm.expectRevert();
        tieredDrop.claimWithSignature(claimRequest, claimSignature);
    }

    function test_revert_claimWithSignature_mintingZeroQuantity() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 0;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        vm.expectRevert("0 qty");
        tieredDrop.claimWithSignature(claimRequest, claimSignature);
    }

    function test_revert_claimWithSignature_notEnoughLazyMintedTokens() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = quantityTier1 + quantityTier2 + quantityTier3 + 1;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        vm.expectRevert("!Tokens");
        tieredDrop.claimWithSignature(claimRequest, claimSignature);
    }

    function test_revert_claimWithSignature_insufficientTokensInTiers() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = "non-exsitent tier 1";
        tiers[1] = "non-exsitent tier 2";

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        vm.expectRevert("Insufficient tokens in tiers.");
        tieredDrop.claimWithSignature(claimRequest, claimSignature);
    }

    ////////////////////////////////////////////////
    //                                            //
    //              reveal tests                  //
    //                                            //
    ////////////////////////////////////////////////

    function _getProvenanceHash(string memory _revealURI, bytes memory _key) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_revealURI, _key, block.chainid));
    }

    function test_state_revealWithScrambleOffset() public {
        // Lazy mint tokens: 3 different tiers: with delayed reveal
        bytes memory encryptedURITier1 = tieredDrop.encryptDecrypt(bytes(baseURITier1), keyTier1);
        bytes memory encryptedURITier2 = tieredDrop.encryptDecrypt(bytes(baseURITier2), keyTier2);
        bytes memory encryptedURITier3 = tieredDrop.encryptDecrypt(bytes(baseURITier3), keyTier3);

        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(
            quantityTier1,
            placeholderURITier1,
            tier1,
            abi.encode(encryptedURITier1, _getProvenanceHash(baseURITier1, keyTier1))
        );
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(
            quantityTier2,
            placeholderURITier2,
            tier2,
            abi.encode(encryptedURITier2, _getProvenanceHash(baseURITier2, keyTier2))
        );
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(
            quantityTier3,
            placeholderURITier3,
            tier3,
            abi.encode(encryptedURITier3, _getProvenanceHash(baseURITier3, keyTier3))
        );

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);

        /**
         *  Check token URIs for tokens of tiers:
         *      - Tier 2: token IDs 0 -> 19 mapped one-to-one to metadata IDs 10 -> 29
         *      - Tier 1: token IDs 20 -> 24 mapped one-to-one to metadata IDs 0 -> 4
         */

        uint256 tier2Id = 10;
        uint256 tier1Id = 0;

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            // console.log(i);
            if (i < 20) {
                assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(placeholderURITier2, uint256(0).toString())));
                tier2Id += 1;
            } else {
                assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(placeholderURITier1, uint256(0).toString())));
                tier1Id += 1;
            }
        }

        // Reveal tokens.
        vm.startPrank(dropAdmin);
        tieredDrop.reveal(0, keyTier1);
        tieredDrop.reveal(1, keyTier2);
        tieredDrop.reveal(2, keyTier3);

        uint256 tier2IdStart = 10;
        uint256 tier2IdEnd = 30;

        uint256 tier1IdStart = 0;
        uint256 tier1IdEnd = 10;

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            bytes32 tokenURIHash = keccak256(abi.encodePacked(tieredDrop.tokenURI(i)));
            bool detected = false;

            if (i < 20) {
                for (uint256 j = tier2IdStart; j < tier2IdEnd; j += 1) {
                    bytes32 expectedURIHash = keccak256(abi.encodePacked(baseURITier2, j.toString()));

                    if (tokenURIHash == expectedURIHash) {
                        detected = true;
                    }

                    if (detected) {
                        break;
                    }
                }
            } else {
                for (uint256 k = tier1IdStart; k < tier1IdEnd; k += 1) {
                    bytes32 expectedURIHash = keccak256(abi.encodePacked(baseURITier1, k.toString()));

                    if (tokenURIHash == expectedURIHash) {
                        detected = true;
                    }

                    if (detected) {
                        break;
                    }
                }
            }

            assertEq(detected, true);
        }
    }

    event URIReveal(uint256 tokenId, string uri);

    ////////////////////////////////////////////////
    //                                            //
    //          getTokensInTierLen tests          //
    //                                            //
    ////////////////////////////////////////////////

    function test_state_getTokensInTierLen() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        vm.warp(claimRequest.validityStartTimestamp);

        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);

        assertEq(tieredDrop.getTokensInTierLen(), 2);

        for (uint256 i = 0; i < 5; i += 1) {
            _setupClaimSignature(tiers, 1);

            vm.warp(claimRequest.validityStartTimestamp);

            vm.prank(claimer);
            tieredDrop.claimWithSignature(claimRequest, claimSignature);
        }

        assertEq(tieredDrop.getTokensInTierLen(), 7);
    }

    ////////////////////////////////////////////////
    //                                            //
    //          getTokensInTier tests             //
    //                                            //
    ////////////////////////////////////////////////

    function test_state_getTokensInTier() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        vm.warp(claimRequest.validityStartTimestamp);

        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);

        TieredDrop.TokenRange[] memory rangesTier1 = tieredDrop.getTokensInTier(tier1, 0, 2);
        assertEq(rangesTier1.length, 1);

        TieredDrop.TokenRange[] memory rangesTier2 = tieredDrop.getTokensInTier(tier2, 0, 2);
        assertEq(rangesTier2.length, 1);

        assertEq(rangesTier1[0].startIdInclusive, 20);
        assertEq(rangesTier1[0].endIdNonInclusive, 25);
        assertEq(rangesTier2[0].startIdInclusive, 0);
        assertEq(rangesTier2[0].endIdNonInclusive, 20);
    }

    ////////////////////////////////////////////////
    //                                            //
    //            getTierForToken tests           //
    //                                            //
    ////////////////////////////////////////////////

    function test_state_getTierForToken() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        vm.warp(claimRequest.validityStartTimestamp);

        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);

        /**
         *  Check token URIs for tokens of tiers:
         *      - Tier 2: token IDs 0 -> 19 mapped one-to-one to metadata IDs 10 -> 29
         *      - Tier 1: token IDs 20 -> 24 mapped one-to-one to metadata IDs 0 -> 4
         */

        uint256 tier2Id = 10;
        uint256 tier1Id = 0;

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            if (i < 20) {
                string memory tierForToken = tieredDrop.getTierForToken(i);
                assertEq(tierForToken, tier2);

                tier2Id += 1;
            } else {
                string memory tierForToken = tieredDrop.getTierForToken(i);
                assertEq(tierForToken, tier1);

                tier1Id += 1;
            }
        }
    }

    ////////////////////////////////////////////////
    //                                            //
    //        getMetadataForAllTiers tests        //
    //                                            //
    ////////////////////////////////////////////////

    // function test_state_getMetadataForAllTiers() public {
    //     // Lazy mint tokens: 3 different tiers
    //     vm.startPrank(dropAdmin);

    //     // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
    //     // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier2, baseURITier2, tier2, "");
    //     // Tier 3: tokenIds assigned 30 -> 60 non-inclusive.
    //     tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

    //     vm.stopPrank();

    //     TieredDrop.TierMetadata[] memory metadataForAllTiers = tieredDrop.getMetadataForAllTiers();

    //     // Tier 1
    //     assertEq(metadataForAllTiers[0].tier, tier1);

    //     TieredDrop.TokenRange[] memory ranges1 = metadataForAllTiers[0].ranges;
    //     assertEq(ranges1.length, 1);
    //     assertEq(ranges1[0].startIdInclusive, 0);
    //     assertEq(ranges1[0].endIdNonInclusive, 10);

    //     string[] memory baseURIs1 = metadataForAllTiers[0].baseURIs;
    //     assertEq(baseURIs1.length, 1);
    //     assertEq(baseURIs1[0], baseURITier1);

    //     // Tier 2
    //     assertEq(metadataForAllTiers[1].tier, tier2);

    //     TieredDrop.TokenRange[] memory ranges2 = metadataForAllTiers[1].ranges;
    //     assertEq(ranges2.length, 1);
    //     assertEq(ranges2[0].startIdInclusive, 10);
    //     assertEq(ranges2[0].endIdNonInclusive, 30);

    //     string[] memory baseURIs2 = metadataForAllTiers[1].baseURIs;
    //     assertEq(baseURIs2.length, 1);
    //     assertEq(baseURIs2[0], baseURITier2);

    //     // Tier 3
    //     assertEq(metadataForAllTiers[2].tier, tier3);

    //     TieredDrop.TokenRange[] memory ranges3 = metadataForAllTiers[2].ranges;
    //     assertEq(ranges3.length, 1);
    //     assertEq(ranges3[0].startIdInclusive, 30);
    //     assertEq(ranges3[0].endIdNonInclusive, 60);

    //     string[] memory baseURIs3 = metadataForAllTiers[2].baseURIs;
    //     assertEq(baseURIs3.length, 1);
    //     assertEq(baseURIs3[0], baseURITier3);
    // }

    ////////////////////////////////////////////////
    //                                            //
    //                audit tests                 //
    //                                            //
    ////////////////////////////////////////////////

    function test_state_claimWithSignature_IssueH1() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 20 non-inclusive.
        tieredDrop.lazyMint(10, baseURITier2, tier2, "");
        // Tier 3: tokenIds assigned 20 -> 50 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        // Tier 2: tokenIds assigned 50 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier2 - 10, baseURITier2, tier2, "");

        vm.stopPrank();

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        vm.warp(claimRequest.validityStartTimestamp);
        vm.prank(claimer);
        tieredDrop.claimWithSignature(claimRequest, claimSignature);
        assertEq(tieredDrop.balanceOf(claimer), claimQuantity);

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            // Outputs:
            //   Checking 0 baseURI2/10
            //   Checking 1 baseURI2/11
            //   Checking 2 baseURI2/12
            //   Checking 3 baseURI2/13
            //   Checking 4 baseURI2/14
            //   Checking 5 baseURI2/15
            //   Checking 6 baseURI2/16
            //   Checking 7 baseURI2/17
            //   Checking 8 baseURI2/18
            //   Checking 9 baseURI2/19
            //   Checking 10 baseURI3/50
            //   Checking 11 baseURI3/51
            //   Checking 12 baseURI3/52
            //   Checking 13 baseURI3/53
            //   Checking 14 baseURI3/54
            //   Checking 15 baseURI3/55
            //   Checking 16 baseURI3/56
            //   Checking 17 baseURI3/57
            //   Checking 18 baseURI3/58
            //   Checking 19 baseURI3/59
            //   Checking 20 baseURI1/0
            //   Checking 21 baseURI1/1
            //   Checking 22 baseURI1/2
            //   Checking 23 baseURI1/3
            //   Checking 24 baseURI1/4
            console.log("Checking", i, tieredDrop.tokenURI(i));
        }
    }

    function test_state_claimWithSignature_IssueH1_2() public {
        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(quantityTier1, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 20 non-inclusive.
        tieredDrop.lazyMint(1, baseURITier2, tier2, ""); // 10 -> 11
        tieredDrop.lazyMint(9, baseURITier2, tier2, ""); // 11 -> 20
        // Tier 3: tokenIds assigned 20 -> 50 non-inclusive.
        tieredDrop.lazyMint(quantityTier3, baseURITier3, tier3, "");

        // Tier 2: tokenIds assigned 50 -> 60 non-inclusive.
        tieredDrop.lazyMint(quantityTier2 - 10, baseURITier2, tier2, "");

        vm.stopPrank();

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256[3] memory claimQuantities = [uint256(1), uint256(3), uint256(21)];
        uint256 claimedCount = 0;
        for (uint256 loop = 0; loop < 3; loop++) {
            uint256 claimQuantity = claimQuantities[loop];
            uint256 offset = claimedCount;

            _setupClaimSignature(tiers, claimQuantity);

            assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

            vm.warp(claimRequest.validityStartTimestamp);
            vm.prank(claimer);
            tieredDrop.claimWithSignature(claimRequest, claimSignature);

            claimedCount += claimQuantity;
            assertEq(tieredDrop.balanceOf(claimer), claimedCount);

            for (uint256 i = offset; i < claimQuantity + (offset); i += 1) {
                // Outputs:
                //   Checking 0 baseURI2/10
                //   Checking 1 baseURI2/11
                //   Checking 2 baseURI2/12
                //   Checking 3 baseURI2/13
                //   Checking 4 baseURI2/14
                //   Checking 5 baseURI2/15
                //   Checking 6 baseURI2/16
                //   Checking 7 baseURI2/17
                //   Checking 8 baseURI2/18
                //   Checking 9 baseURI2/19
                //   Checking 10 baseURI3/50
                //   Checking 11 baseURI3/51
                //   Checking 12 baseURI3/52
                //   Checking 13 baseURI3/53
                //   Checking 14 baseURI3/54
                //   Checking 15 baseURI3/55
                //   Checking 16 baseURI3/56
                //   Checking 17 baseURI3/57
                //   Checking 18 baseURI3/58
                //   Checking 19 baseURI3/59
                //   Checking 20 baseURI1/0
                //   Checking 21 baseURI1/1
                //   Checking 22 baseURI1/2
                //   Checking 23 baseURI1/3
                //   Checking 24 baseURI1/4
                console.log("Checking", i, tieredDrop.tokenURI(i));
            }
        }
    }
}

contract TieredDropBechmarkTest is BaseTest {
    using Strings for uint256;

    TieredDrop public tieredDrop;

    address internal dropAdmin;
    address internal claimer;

    // Signature params
    address internal deployerSigner;
    bytes32 internal typehashGenericRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    // Lazy mint variables
    uint256 internal quantityTier1 = 10;
    string internal tier1 = "tier1";
    string internal baseURITier1 = "baseURI1/";
    string internal placeholderURITier1 = "placeholderURI1/";
    bytes internal keyTier1 = "tier1_key";

    uint256 internal quantityTier2 = 20;
    string internal tier2 = "tier2";
    string internal baseURITier2 = "baseURI2/";
    string internal placeholderURITier2 = "placeholderURI2/";
    bytes internal keyTier2 = "tier2_key";

    uint256 internal quantityTier3 = 30;
    string internal tier3 = "tier3";
    string internal baseURITier3 = "baseURI3/";
    string internal placeholderURITier3 = "placeholderURI3/";
    bytes internal keyTier3 = "tier3_key";

    function setUp() public virtual override {
        super.setUp();

        dropAdmin = getActor(1);
        claimer = getActor(2);

        // Deploy implementation.
        address tieredDropImpl = address(new TieredDrop());

        // Deploy proxy pointing to implementaion.
        vm.prank(dropAdmin);
        tieredDrop = TieredDrop(
            address(
                new TWProxy(
                    tieredDropImpl,
                    abi.encodeCall(
                        TieredDrop.initialize,
                        (dropAdmin, "Tiered Drop", "TD", "ipfs://", new address[](0), dropAdmin, dropAdmin, 0)
                    )
                )
            )
        );

        // ====== signature params

        deployerSigner = signer;
        vm.prank(dropAdmin);
        tieredDrop.grantRole(keccak256("MINTER_ROLE"), deployerSigner);

        typehashGenericRequest = keccak256(
            "GenericRequest(uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid,bytes data)"
        );
        nameHash = keccak256(bytes("SignatureAction"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tieredDrop))
        );

        // ======

        // Lazy mint tokens: 3 different tiers
        vm.startPrank(dropAdmin);

        // Tier 1: tokenIds assigned 0 -> 10 non-inclusive.
        tieredDrop.lazyMint(totalQty, baseURITier1, tier1, "");
        // Tier 2: tokenIds assigned 10 -> 30 non-inclusive.
        tieredDrop.lazyMint(totalQty, baseURITier2, tier2, "");

        vm.stopPrank();

        /**
         *  Claim tokens.
         *      - Order of priority: [tier2, tier1]
         *      - Total quantity: 25. [20 from tier2, 5 from tier1]
         */

        string[] memory tiers = new string[](2);
        tiers[0] = tier2;
        tiers[1] = tier1;

        uint256 claimQuantity = totalQty;

        for (uint256 i = 0; i < claimQuantity; i += 1) {
            _setupClaimSignature(tiers, 1);

            vm.warp(claimRequest.validityStartTimestamp);

            vm.prank(claimer);
            tieredDrop.claimWithSignature(claimRequest, claimSignature);
        }
    }

    TieredDrop.GenericRequest internal claimRequest;
    bytes internal claimSignature;

    uint256 internal nonce;

    function _setupClaimSignature(string[] memory _orderedTiers, uint256 _totalQuantity) internal {
        claimRequest.validityStartTimestamp = 1000;
        claimRequest.validityEndTimestamp = 2000;
        claimRequest.uid = keccak256(abi.encodePacked(nonce));
        nonce += 1;
        claimRequest.data = abi.encode(
            _orderedTiers,
            claimer,
            address(0),
            0,
            dropAdmin,
            _totalQuantity,
            0,
            NATIVE_TOKEN
        );

        bytes memory encodedRequest = abi.encode(
            typehashGenericRequest,
            claimRequest.validityStartTimestamp,
            claimRequest.validityEndTimestamp,
            claimRequest.uid,
            keccak256(bytes(claimRequest.data))
        );

        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        claimSignature = abi.encodePacked(r, s, v);
    }

    // What does it take to exhaust the 550mil RPC view fn gas limit ?

    // 10_000: 67 mil gas (67,536,754)
    uint256 internal totalQty = 10_000;

    function test_banchmark_getTokensInTier() public view {
        tieredDrop.getTokensInTier(tier1, 0, totalQty);
    }

    function test_banchmark_getTokensInTier_ten() public view {
        tieredDrop.getTokensInTier(tier1, 0, 10);
    }

    function test_banchmark_getTokensInTier_hundred() public view {
        tieredDrop.getTokensInTier(tier1, 0, 100);
    }
}
