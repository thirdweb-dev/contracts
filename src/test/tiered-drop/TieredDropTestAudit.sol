// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";
import "contracts/lib/TWStrings.sol";

import { TieredDrop } from "contracts/tiered-drop/TieredDrop.sol";
import "contracts/extension/interface/IOperatorFilterToggle.sol";
import { TieredDropLogic, ERC721AUpgradeable, DelayedReveal, LazyMintWithTier } from "contracts/tiered-drop/extension/TieredDropLogic.sol";
import { PermissionsEnumerable } from "contracts/extension/PermissionsEnumerable.sol";

import "lib/dynamic-contracts/src/interface/IExtension.sol";

import { TWProxy } from "contracts/TWProxy.sol";

contract TieredDropTestAudit is BaseTest, IExtension {
    using TWStrings for uint256;

    TieredDropLogic public tieredDrop;

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

    string constant MAINNET_RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/KWcWxd0rnltoLKwXMc8ecMK7lYffqobD";
    address constant OPERATOR_FILTER_REGISTRY = address(0xAAeB6D7670E522A718067333cd4E);

    function setUp() public virtual override {
        uint256 forkId = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(forkId);

        super.setUp();

        dropAdmin = getActor(1);
        claimer = getActor(2);

        // Deploy implementation.
        Extension[] memory extensions = _setupExtensions();
        address tieredDropImpl = address(new TieredDrop(extensions));

        // Deploy proxy pointing to implementaion.
        vm.prank(dropAdmin);
        tieredDrop = TieredDropLogic(
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
        Permissions(address(tieredDrop)).grantRole(keccak256("MINTER_ROLE"), deployerSigner);

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

    function _setupExtensions() internal returns (Extension[] memory extensions) {
        extensions = new Extension[](2);

        // Extension: Permissions
        address permissions = address(new PermissionsEnumerable());

        Extension memory extension_permissions;
        extension_permissions.metadata = ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: permissions
        });

        extension_permissions.functions = new ExtensionFunction[](4);
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
            PermissionsEnumerable.getRoleMemberCount.selector,
            "getRoleMemberCount(bytes32)"
        );

        extensions[0] = extension_permissions;

        address tieredDropLogic = address(new TieredDropLogic());

        Extension memory extension_td;
        extension_td.metadata = ExtensionMetadata({
            name: "TieredDropLogic",
            metadataURI: "ipfs://TieredDropLogic",
            implementation: tieredDropLogic
        });

        extension_td.functions = new ExtensionFunction[](19);
        extension_td.functions[0] = ExtensionFunction(TieredDropLogic.tokenURI.selector, "tokenURI(uint256)");
        extension_td.functions[1] = ExtensionFunction(
            TieredDropLogic.lazyMint.selector,
            "lazyMint(uint256,string,string,bytes)"
        );
        extension_td.functions[2] = ExtensionFunction(TieredDropLogic.reveal.selector, "reveal(uint256,bytes)");
        extension_td.functions[3] = ExtensionFunction(
            TieredDropLogic.claimWithSignature.selector,
            "claimWithSignature((uint128,uint128,bytes32,bytes),bytes)"
        );
        extension_td.functions[4] = ExtensionFunction(
            TieredDropLogic.getTierForToken.selector,
            "getTierForToken(uint256)"
        );
        extension_td.functions[5] = ExtensionFunction(
            TieredDropLogic.getTokensInTierLen.selector,
            "getTokensInTierLen()"
        );
        extension_td.functions[6] = ExtensionFunction(
            TieredDropLogic.getTokensInTier.selector,
            "getTokensInTier(string,uint256,uint256)"
        );
        extension_td.functions[7] = ExtensionFunction(TieredDropLogic.totalMinted.selector, "totalMinted()");
        extension_td.functions[8] = ExtensionFunction(
            TieredDropLogic.totalMintedInTier.selector,
            "totalMintedInTier(string)"
        );
        extension_td.functions[9] = ExtensionFunction(
            TieredDropLogic.nextTokenIdToMint.selector,
            "nextTokenIdToMint()"
        );
        extension_td.functions[10] = ExtensionFunction(TieredDropLogic.getApproved.selector, "getApproved(uint256)");
        extension_td.functions[11] = ExtensionFunction(
            TieredDropLogic.isApprovedForAll.selector,
            "isApprovedForAll(address,address)"
        );
        extension_td.functions[12] = ExtensionFunction(
            TieredDropLogic.setApprovalForAll.selector,
            "setApprovalForAll(address,bool)"
        );
        extension_td.functions[13] = ExtensionFunction(TieredDropLogic.approve.selector, "approve(address,uint256)");
        extension_td.functions[14] = ExtensionFunction(
            TieredDropLogic.transferFrom.selector,
            "transferFrom(address,address,uint256)"
        );
        extension_td.functions[15] = ExtensionFunction(ERC721AUpgradeable.balanceOf.selector, "balanceOf(address)");
        extension_td.functions[16] = ExtensionFunction(
            DelayedReveal.encryptDecrypt.selector,
            "encryptDecrypt(bytes,bytes)"
        );
        extension_td.functions[17] = ExtensionFunction(
            IOperatorFilterToggle.setOperatorRestriction.selector,
            "setOperatorRestriction(bool)"
        );
        extension_td.functions[18] = ExtensionFunction(ERC721AUpgradeable.ownerOf.selector, "ownerOf(uint256)");

        extensions[1] = extension_td;
    }

    TieredDropLogic.GenericRequest internal claimRequest;
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
    //          audit tests                       //
    //                                            //
    ////////////////////////////////////////////////

    function test_firstPermissionsNotAddedToEnumerable() public {
        uint256 num = PermissionsEnumerable(address(tieredDrop)).getRoleMemberCount(0x00);

        // this should be 1
        // assertEq(num, 0);
        assertEq(num, 1);

        vm.prank(dropAdmin);

        PermissionsEnumerable(address(tieredDrop)).grantRole(0x00, claimer);

        num = PermissionsEnumerable(address(tieredDrop)).getRoleMemberCount(0x00);

        // this should be 2
        // assertEq(num, 1);
        assertEq(num, 2);
    }
}
