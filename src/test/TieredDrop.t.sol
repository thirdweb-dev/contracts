// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./utils/BaseTest.sol";
import "contracts/lib/TWStrings.sol";

import { TieredDrop } from "contracts/tiered-drop/TieredDrop.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract TieredDropTest is BaseTest {
    using TWStrings for uint256;

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

    bytes private emptyEncodedBytes = abi.encode("", "");

    function setUp() public override {
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

    function _setupClaimSignature(string[] memory _orderedTiers, uint256 _totalQuantity) private {
        claimRequest.validityStartTimestamp = 1000;
        claimRequest.validityEndTimestamp = 2000;
        claimRequest.uid = bytes32("UID");
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
            claimRequest.data
        );

        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        claimSignature = abi.encodePacked(r, s, v);
    }

    function test_flow() public {
        // Lazy mint tokens: 3 different tiers
        uint256 quantityTier1 = 10;
        string memory tier1 = "tier1";
        string memory baseURITier1 = "baseURI1/";

        uint256 quantityTier2 = 20;
        string memory tier2 = "tier2";
        string memory baseURITier2 = "baseURI2/";

        uint256 quantityTier3 = 30;
        string memory tier3 = "tier3";
        string memory baseURITier3 = "baseURI3/";

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
        tiers[0] = tier1;
        tiers[1] = tier2;

        uint256 claimQuantity = 25;

        _setupClaimSignature(tiers, claimQuantity);

        assertEq(tieredDrop.hasRole(keccak256("MINTER_ROLE"), deployerSigner), true);

        // vm.prank(claimer);
        // tieredDrop.claimWithSignature(claimRequest, claimSignature);

        /**
         *  Check token URIs for tokens of tiers:
         *      - Tier 2: token IDs 0 -> 19 mapped one-to-one to metadata IDs 10 -> 29
         *      - Tier 1: token IDs 20 -> 24 mapped one-to-one to metadata IDs 0 -> 4
         */

        // uint256 tier2Id = 10;
        // uint256 tier1Id = 0;

        // for (uint256 i = 0; i < claimQuantity; i += 1) {
        //     if (i < 20) {
        //         assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(baseURITier2, tier2Id.toString())));
        //         tier2Id += 1;
        //     } else {
        //         assertEq(tieredDrop.tokenURI(i), string(abi.encodePacked(baseURITier1, tier1Id.toString())));
        //         tier1Id += 1;
        //     }
        // }
    }
}
