// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IExtension } from "@thirdweb-dev/dynamic-contracts/src/interface/IExtension.sol";

import { EvolvingNFT } from "contracts/prebuilts/evolving-nfts/EvolvingNFT.sol";
import { EvolvingNFTLogic } from "contracts/prebuilts/evolving-nfts/EvolvingNFTLogic.sol";
import { RulesEngineExtension } from "contracts/prebuilts/evolving-nfts/extension/RulesEngineExtension.sol";

import { IDrop } from "contracts/extension/interface/IDrop.sol";
import { Drop } from "contracts/extension/upgradeable/Drop.sol";
import { SharedMetadataBatch } from "contracts/extension/upgradeable/SharedMetadataBatch.sol";
import { ISharedMetadataBatch } from "contracts/extension/interface/ISharedMetadataBatch.sol";
import { RulesEngine, IRulesEngine } from "contracts/extension/upgradeable/RulesEngine.sol";
import { NFTMetadataRenderer } from "contracts/lib/NFTMetadataRenderer.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";
import { PermissionsEnumerable as DynamicPermissionsEnumerable } from "contracts/extension/upgradeable/PermissionsEnumerable.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { Permissions } from "contracts/extension/Permissions.sol";
import { IERC721 } from "./mocks/MockERC721.sol";
import "./utils/BaseTest.sol";

contract EvolvingNFTTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    event SharedMetadataUpdated(
        bytes32 indexed id,
        string name,
        string description,
        string imageURI,
        string animationURI
    );

    address public evolvingNFT;

    mapping(uint256 => ISharedMetadataBatch.SharedMetadataInfo) public sharedMetadataBatch;

    bytes private emptyEncodedBytes = abi.encode("", "");

    // Scores
    uint256 private score1 = 10;
    uint256 private score2 = 40;
    uint256 private score3 = 100;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        // Setting up default extension.
        IExtension.Extension memory evolvingNftExtension;
        IExtension.Extension memory permissionsExtension;
        IExtension.Extension memory rulesEngineExtension;

        evolvingNftExtension.metadata = IExtension.ExtensionMetadata({
            name: "EvolvingNFTLogic",
            metadataURI: "ipfs://EvolvingNFTLogic",
            implementation: address(new EvolvingNFTLogic())
        });
        permissionsExtension.metadata = IExtension.ExtensionMetadata({
            name: "Permissions",
            metadataURI: "ipfs://Permissions",
            implementation: address(new DynamicPermissionsEnumerable())
        });
        rulesEngineExtension.metadata = IExtension.ExtensionMetadata({
            name: "RulesEngine",
            metadataURI: "ipfs://RulesEngine",
            implementation: address(new RulesEngineExtension())
        });

        evolvingNftExtension.functions = new IExtension.ExtensionFunction[](11);
        rulesEngineExtension.functions = new IExtension.ExtensionFunction[](4);
        permissionsExtension.functions = new IExtension.ExtensionFunction[](4);

        rulesEngineExtension.functions[0] = IExtension.ExtensionFunction(
            RulesEngine.getScore.selector,
            "getScore(address)"
        );
        rulesEngineExtension.functions[1] = IExtension.ExtensionFunction(
            RulesEngine.createRuleThreshold.selector,
            "createRuleThreshold((address,uint8,uint256,uint256,uint256))"
        );
        rulesEngineExtension.functions[2] = IExtension.ExtensionFunction(
            RulesEngine.deleteRule.selector,
            "deleteRule(bytes32)"
        );
        rulesEngineExtension.functions[3] = IExtension.ExtensionFunction(
            RulesEngine.getRulesEngineOverride.selector,
            "getRulesEngineOverride()"
        );
        evolvingNftExtension.functions[0] = IExtension.ExtensionFunction(
            IDrop.claim.selector,
            "claim(address,uint256,address,uint256,(bytes32[],uint256,uint256,address),bytes)"
        );
        evolvingNftExtension.functions[1] = IExtension.ExtensionFunction(
            SharedMetadataBatch.setSharedMetadata.selector,
            "setSharedMetadata((string,string,string,string),bytes32)"
        );
        evolvingNftExtension.functions[2] = IExtension.ExtensionFunction(
            IDrop.setClaimConditions.selector,
            "setClaimConditions((uint256,uint256,uint256,uint256,bytes32,uint256,address,string)[],bool)"
        );
        evolvingNftExtension.functions[3] = IExtension.ExtensionFunction(
            EvolvingNFTLogic.tokenURI.selector,
            "tokenURI(uint256)"
        );
        evolvingNftExtension.functions[4] = IExtension.ExtensionFunction(
            IERC721Upgradeable.transferFrom.selector,
            "transferFrom(address,address,uint256)"
        );
        evolvingNftExtension.functions[5] = IExtension.ExtensionFunction(IERC721.ownerOf.selector, "ownerOf(uint256)");
        evolvingNftExtension.functions[6] = IExtension.ExtensionFunction(
            Drop.getSupplyClaimedByWallet.selector,
            "getSupplyClaimedByWallet(uint256,address)"
        );
        evolvingNftExtension.functions[7] = IExtension.ExtensionFunction(
            Drop.getActiveClaimConditionId.selector,
            "getActiveClaimConditionId()"
        );
        evolvingNftExtension.functions[8] = IExtension.ExtensionFunction(
            Drop.getClaimConditionById.selector,
            "getClaimConditionById(uint256)"
        );
        evolvingNftExtension.functions[9] = IExtension.ExtensionFunction(
            Drop.claimCondition.selector,
            "claimCondition()"
        );
        evolvingNftExtension.functions[10] = IExtension.ExtensionFunction(
            SharedMetadataBatch.deleteSharedMetadata.selector,
            "deleteSharedMetadata(bytes32)"
        );
        permissionsExtension.functions[0] = IExtension.ExtensionFunction(
            Permissions.renounceRole.selector,
            "renounceRole(bytes32,address)"
        );
        permissionsExtension.functions[1] = IExtension.ExtensionFunction(
            Permissions.revokeRole.selector,
            "revokeRole(bytes32,address)"
        );
        permissionsExtension.functions[2] = IExtension.ExtensionFunction(
            Permissions.grantRole.selector,
            "grantRole(bytes32,address)"
        );
        permissionsExtension.functions[3] = IExtension.ExtensionFunction(
            Permissions.hasRole.selector,
            "hasRole(bytes32,address)"
        );

        IExtension.Extension[] memory extensions = new IExtension.Extension[](3);
        extensions[0] = evolvingNftExtension;
        extensions[1] = permissionsExtension;
        extensions[2] = rulesEngineExtension;

        address evolvingNftImpl = address(new EvolvingNFT(extensions));

        vm.prank(deployer);
        evolvingNFT = address(
            new TWProxy(
                evolvingNftImpl,
                abi.encodeCall(
                    EvolvingNFT.initialize,
                    (deployer, NAME, SYMBOL, CONTRACT_URI, forwarders(), saleRecipient, royaltyRecipient, royaltyBps)
                )
            )
        );

        assertEq(Permissions(evolvingNFT).hasRole(0x00, deployer), true);

        sharedMetadataBatch[0] = ISharedMetadataBatch.SharedMetadataInfo({
            name: "Default",
            description: "Default metadata",
            imageURI: "https://default.com/1",
            animationURI: "https://default.com/1"
        });

        sharedMetadataBatch[score1] = ISharedMetadataBatch.SharedMetadataInfo({
            name: "Test 1",
            description: "Test 1",
            imageURI: "https://test.com/1",
            animationURI: "https://test.com/1"
        });

        sharedMetadataBatch[score1 + score2] = ISharedMetadataBatch.SharedMetadataInfo({
            name: "Test 2",
            description: "Test 2",
            imageURI: "https://test.com/2",
            animationURI: "https://test.com/2"
        });

        sharedMetadataBatch[score1 + score2 + score3] = ISharedMetadataBatch.SharedMetadataInfo({
            name: "Test 3",
            description: "Test 3",
            imageURI: "https://test.com/3",
            animationURI: "https://test.com/3"
        });

        vm.deal(deployer, 1_000 ether);
    }

    /*///////////////////////////////////////////////////////////////
                            Rules test
    //////////////////////////////////////////////////////////////*/

    function test_state_evolvingNFT() public {
        /**
         *  Set shared metadata for the following scores:
         *
         *  default: `0`
         *      NFT owner owns no relevant tokens.
         *  score_1: `10`
         *      NFT owner owns 10 `MockERC20` tokens.
         *  score_1 + score_2: `50`
         *      NFT owner additionally owns 1 `MockERC721` NFT.
         *  score_1 + score_2 + score_3: `150`
         *      NFT owner addtionally owns 5 `MockERC1155` NFTs of tokenID 3.
         */

        // Set shared metadata
        vm.startPrank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[score1], bytes32(score1));
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(
            sharedMetadataBatch[score1 + score2],
            bytes32(score1 + score2)
        );
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(
            sharedMetadataBatch[score1 + score2 + score3],
            bytes32(score1 + score2 + score3)
        );
        vm.stopPrank();

        // Set rules
        vm.prank(deployer);
        RulesEngine(evolvingNFT).createRuleThreshold(
            IRulesEngine.RuleTypeThreshold({
                token: address(erc20),
                tokenType: IRulesEngine.TokenType.ERC20,
                tokenId: 0,
                balance: 10,
                score: score1
            })
        );
        vm.prank(deployer);
        RulesEngine(evolvingNFT).createRuleThreshold(
            IRulesEngine.RuleTypeThreshold({
                token: address(erc721),
                tokenType: IRulesEngine.TokenType.ERC721,
                tokenId: 0,
                balance: 1,
                score: score2
            })
        );
        vm.prank(deployer);
        RulesEngine(evolvingNFT).createRuleThreshold(
            IRulesEngine.RuleTypeThreshold({
                token: address(erc1155),
                tokenType: IRulesEngine.TokenType.ERC1155,
                tokenId: 3,
                balance: 5,
                score: score3
            })
        );

        // `Receiver` mints token
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 0;
        conditions[0].currency = address(erc20);
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 1, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0

        // NFT should return default metadata.
        string memory uri0 = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri0,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[0].name,
                description: sharedMetadataBatch[0].description,
                imageURI: sharedMetadataBatch[0].imageURI,
                animationURI: sharedMetadataBatch[0].animationURI,
                tokenOfEdition: 1
            })
        );

        // NFT should return 1st tier of metadata.
        vm.prank(deployer);
        erc20.mint(receiver, 10 ether);
        assertEq(RulesEngine(evolvingNFT).getScore(receiver), uint256(bytes32(score1)));

        string memory uri1 = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri1,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[score1].name,
                description: sharedMetadataBatch[score1].description,
                imageURI: sharedMetadataBatch[score1].imageURI,
                animationURI: sharedMetadataBatch[score1].animationURI,
                tokenOfEdition: 1
            })
        );

        // NFT should return 2nd tier of metadata.
        vm.prank(deployer);
        erc721.mint(receiver, 1);
        assertEq(RulesEngine(evolvingNFT).getScore(receiver), uint256(bytes32(score1 + score2)));

        string memory uri2 = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri2,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[score1 + score2].name,
                description: sharedMetadataBatch[score1 + score2].description,
                imageURI: sharedMetadataBatch[score1 + score2].imageURI,
                animationURI: sharedMetadataBatch[score1 + score2].animationURI,
                tokenOfEdition: 1
            })
        );

        // NFT should return 3rd tier of metadata.
        vm.prank(deployer);
        erc1155.mint(receiver, 3, 5, "");
        assertEq(RulesEngine(evolvingNFT).getScore(receiver), uint256(bytes32(score1 + score2 + score3)));

        string memory uri3 = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri3,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[score1 + score2 + score3].name,
                description: sharedMetadataBatch[score1 + score2 + score3].description,
                imageURI: sharedMetadataBatch[score1 + score2 + score3].imageURI,
                animationURI: sharedMetadataBatch[score1 + score2 + score3].animationURI,
                tokenOfEdition: 1
            })
        );
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

        Permissions(evolvingNFT).renounceRole(role, caller);
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

        Permissions(evolvingNFT).revokeRole(role, target);
    }

    /**
     *  @dev Tests whether contract reverts when a role is granted to an existent role holder.
     */
    function test_revert_grant_role_to_account_with_role() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);

        Permissions(evolvingNFT).grantRole(role, receiver);

        vm.expectRevert("Can only grant to non holders");
        Permissions(evolvingNFT).grantRole(role, receiver);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_grant_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        // check if admin and address(0) have transfer role in the beginning
        bool checkAddressZero = Permissions(evolvingNFT).hasRole(role, address(0));
        bool checkAdmin = Permissions(evolvingNFT).hasRole(role, deployer);
        assertTrue(checkAddressZero);
        assertTrue(checkAdmin);

        // check if transfer role can be granted to a non-holder
        address receiver = getActor(0);
        vm.startPrank(deployer);
        Permissions(evolvingNFT).grantRole(role, receiver);

        // expect revert when granting to a holder
        vm.expectRevert("Can only grant to non holders");
        Permissions(evolvingNFT).grantRole(role, receiver);

        // check if receiver has transfer role
        bool checkReceiver = Permissions(evolvingNFT).hasRole(role, receiver);
        assertTrue(checkReceiver);

        // check if role is correctly revoked
        Permissions(evolvingNFT).revokeRole(role, receiver);
        checkReceiver = Permissions(evolvingNFT).hasRole(role, receiver);
        assertFalse(checkReceiver);
        Permissions(evolvingNFT).revokeRole(role, address(0));
        checkAddressZero = Permissions(evolvingNFT).hasRole(role, address(0));
        assertFalse(checkAddressZero);

        vm.stopPrank();
    }

    /**
     *  note: Testing transfer of tokens when transfer-role is restricted
     */
    function test_claim_transferRole() public {
        assertEq(Permissions(evolvingNFT).hasRole(0x00, deployer), true);

        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        IDrop(evolvingNFT).claim(receiver, 1, address(0), 0, alp, "");

        // revoke transfer role from address(0)
        vm.prank(deployer);
        Permissions(evolvingNFT).revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.prank(receiver);
        vm.expectRevert(bytes("!T"));
        IERC721(evolvingNFT).transferFrom(receiver, address(123), 1);
    }

    function test_claimCondition_with_startTimestamp() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].startTimestamp = 100;
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.warp(99);
        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("!CONDITION.");
        IDrop(evolvingNFT).claim(receiver, 1, address(0), 0, alp, "");

        vm.warp(100);
        vm.prank(getActor(4), getActor(4));
        IDrop(evolvingNFT).claim(receiver, 1, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            Set Shared Metadata Tests
    //////////////////////////////////////////////////////////////*/

    /*
     *  note: Testing state changes; set shared metadata for tokens.
     */
    function test_state_sharedMetadata() public {
        // SET METADATA
        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[score1], bytes32(0));

        // CLAIM 1 TOKEN
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 0, alp, "");

        string memory uri = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[score1].name,
                description: sharedMetadataBatch[score1].description,
                imageURI: sharedMetadataBatch[score1].imageURI,
                animationURI: sharedMetadataBatch[score1].animationURI,
                tokenOfEdition: 1
            })
        );
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls setSharedMetadata function.
     */
    function test_revert_setSharedMetadata_MINTER_ROLE() public {
        vm.expectRevert();
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
    }

    /**
     *  note: Testing event emission; shared metadata set.
     */
    function test_event_setSharedMetadata_SharedMetadataUpdated() public {
        vm.startPrank(deployer);

        vm.expectEmit(false, false, false, false);
        emit SharedMetadataUpdated(
            bytes32(0),
            sharedMetadataBatch[score1].name,
            sharedMetadataBatch[score1].description,
            sharedMetadataBatch[score1].imageURI,
            sharedMetadataBatch[score1].animationURI
        );
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[score1], bytes32(0));

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; exceed max claimable supply.
     */
    function test_revert_claimCondition_exceedMaxClaimableSupply() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        IDrop(evolvingNFT).claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert("!MaxSupply");
        vm.prank(getActor(6), getActor(6));
        IDrop(evolvingNFT).claim(receiver, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 0, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 101, address(0), 0, alp, "");

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 101, address(0), 0, alp, "");
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            100
        );
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        vm.expectRevert("!PriceOrCurrency");
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 0, alp, "");

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(evolvingNFT, 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 5, alp, "");
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            100
        );
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = type(uint256).max;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(evolvingNFT, 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 10, alp, "");
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            100
        );
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 0;
        alp.pricePerToken = 5;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(evolvingNFT, 10000);

        bytes memory errorQty = "!Qty";
        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 100, address(erc20), 5, alp, ""); // trying to claim more than general limit

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 10, address(erc20), 5, alp, "");
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            10
        );
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        // bytes32[] memory proofs = new bytes32[](0);

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, x - 5, address(0), 0, alp, "");
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            x - 5
        );

        bytes memory errorQty = "!Qty";

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 5, address(0), 0, alp, "");
        assertEq(
            Drop(evolvingNFT).getSupplyClaimedByWallet(Drop(evolvingNFT).getActiveClaimConditionId(), receiver),
            x
        );

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 5, address(0), 0, alp, ""); // quantity limit already claimed
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        IDrop(evolvingNFT).claim(receiver, 100, address(0), 0, alp, "");

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        IDrop(evolvingNFT).claim(receiver, 100, address(0), 0, alp, "");

        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        IDrop(evolvingNFT).claim(receiver, 100, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            setClaimConditions
    //////////////////////////////////////////////////////////////*/

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 currentStartId = 0;
        uint256 count = 0;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        IDrop(evolvingNFT).setClaimConditions(conditions, false);
        (currentStartId, count) = Drop(evolvingNFT).claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        IDrop(evolvingNFT).setClaimConditions(conditions, false);
        (currentStartId, count) = Drop(evolvingNFT).claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        IDrop(evolvingNFT).setClaimConditions(conditions, true);
        (currentStartId, count) = Drop(evolvingNFT).claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        IDrop(evolvingNFT).setClaimConditions(conditions, true);
        (currentStartId, count) = Drop(evolvingNFT).claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 activeConditionId = 0;

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerWallet = 12;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerWallet = 22;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerWallet = 32;
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.expectRevert("!CONDITION.");
        Drop(evolvingNFT).getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = Drop(evolvingNFT).getActiveClaimConditionId();
        assertEq(activeConditionId, 0);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).startTimestamp, 10);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).quantityLimitPerWallet, 12);

        vm.warp(20);
        activeConditionId = Drop(evolvingNFT).getActiveClaimConditionId();
        assertEq(activeConditionId, 1);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).startTimestamp, 20);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).quantityLimitPerWallet, 22);

        vm.warp(30);
        activeConditionId = Drop(evolvingNFT).getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).startTimestamp, 30);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        assertEq(Drop(evolvingNFT).getClaimConditionById(activeConditionId).quantityLimitPerWallet, 32);

        vm.warp(40);
        assertEq(Drop(evolvingNFT).getActiveClaimConditionId(), 2);
    }

    /*///////////////////////////////////////////////////////////////
                        Audit POC tests
    //////////////////////////////////////////////////////////////*/

    function test_state_incorrectTokenUri() public {
        // Set shared metadata
        vm.startPrank(deployer);
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[0], bytes32(0));
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(sharedMetadataBatch[score1], bytes32(score1));
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(
            sharedMetadataBatch[score1 + score2],
            bytes32(score1 + score2)
        );
        SharedMetadataBatch(evolvingNFT).setSharedMetadata(
            sharedMetadataBatch[score1 + score2 + score3],
            bytes32(score1 + score2 + score3)
        );

        // Delete metadata at index "score1"
        // Now the order of metadata ids is: 0, 150, 50
        SharedMetadataBatch(evolvingNFT).deleteSharedMetadata(bytes32(score1));
        vm.stopPrank();

        // Set rules
        vm.prank(deployer);
        RulesEngine(evolvingNFT).createRuleThreshold(
            IRulesEngine.RuleTypeThreshold({
                token: address(erc20),
                tokenType: IRulesEngine.TokenType.ERC20,
                tokenId: 0,
                balance: 10,
                score: score1 + score2 + score3
            })
        );

        // `Receiver` mints token
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

        IDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        IDrop.ClaimCondition[] memory conditions = new IDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 0;
        conditions[0].currency = address(erc20);
        vm.prank(deployer);
        IDrop(evolvingNFT).setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        IDrop(evolvingNFT).claim(receiver, 1, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0

        // NFT should return metadata of a rule at "score1 + score2 + score3"
        // It used to return metadata for "score1 + score2", but now this is fixed.
        erc20.mint(receiver, 10 ether);
        string memory uri = EvolvingNFTLogic(evolvingNFT).tokenURI(1);
        assertEq(
            uri,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadataBatch[score1 + score2 + score3].name,
                description: sharedMetadataBatch[score1 + score2 + score3].description,
                imageURI: sharedMetadataBatch[score1 + score2 + score3].imageURI,
                animationURI: sharedMetadataBatch[score1 + score2 + score3].animationURI,
                tokenOfEdition: 1
            })
        );
    }
}
