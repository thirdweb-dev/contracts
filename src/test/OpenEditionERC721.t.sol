// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC721AUpgradeable, OpenEditionERC721, ISharedMetadata } from "contracts/OpenEditionERC721.sol";
import { NFTMetadataRenderer } from "contracts/lib/NFTMetadataRendererLib.sol";
import { TWProxy } from "contracts/TWProxy.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "./utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OpenEditionERC721Test is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    event SharedMetadataUpdated(string name, string description, string imageURI, string animationURI);

    OpenEditionERC721 public openEdition;
    ISharedMetadata.SharedMetadataInfo public sharedMetadata;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        address openEditionImpl = address(new OpenEditionERC721());

        vm.prank(deployer);
        openEdition = OpenEditionERC721(
            address(
                new TWProxy(
                    openEditionImpl,
                    abi.encodeCall(
                        OpenEditionERC721.initialize,
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
        );

        sharedMetadata = ISharedMetadata.SharedMetadataInfo({
            name: "Test",
            description: "Test",
            imageURI: "https://test.com",
            animationURI: "https://test.com"
        });

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
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
                TWStrings.toHexString(uint160(caller), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
        );

        openEdition.renounceRole(role, caller);
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
                TWStrings.toHexString(uint160(target), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
        );

        openEdition.revokeRole(role, target);
    }

    /**
     *  @dev Tests whether contract reverts when a role is granted to an existent role holder.
     */
    function test_revert_grant_role_to_account_with_role() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);

        openEdition.grantRole(role, receiver);

        vm.expectRevert("Can only grant to non holders");
        openEdition.grantRole(role, receiver);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_grant_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        // check if admin and address(0) have transfer role in the beginning
        bool checkAddressZero = openEdition.hasRole(role, address(0));
        bool checkAdmin = openEdition.hasRole(role, deployer);
        assertTrue(checkAddressZero);
        assertTrue(checkAdmin);

        // check if transfer role can be granted to a non-holder
        address receiver = getActor(0);
        vm.startPrank(deployer);
        openEdition.grantRole(role, receiver);

        // expect revert when granting to a holder
        vm.expectRevert("Can only grant to non holders");
        openEdition.grantRole(role, receiver);

        // check if receiver has transfer role
        bool checkReceiver = openEdition.hasRole(role, receiver);
        assertTrue(checkReceiver);

        // check if role is correctly revoked
        openEdition.revokeRole(role, receiver);
        checkReceiver = openEdition.hasRole(role, receiver);
        assertFalse(checkReceiver);
        openEdition.revokeRole(role, address(0));
        checkAddressZero = openEdition.hasRole(role, address(0));
        assertFalse(checkAddressZero);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_getRoleMember_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        uint256 roleMemberCount = openEdition.getRoleMemberCount(role);
        assertEq(roleMemberCount, 2);

        address roleMember = openEdition.getRoleMember(role, 1);
        assertEq(roleMember, address(0));

        vm.startPrank(deployer);
        openEdition.grantRole(role, address(2));
        openEdition.grantRole(role, address(3));
        openEdition.grantRole(role, address(4));

        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
        }
        console.log("");

        openEdition.revokeRole(role, address(2));
        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
        }
        console.log("");

        openEdition.revokeRole(role, address(0));
        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
        }
        console.log("");

        openEdition.grantRole(role, address(5));
        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
        }
        console.log("");

        openEdition.grantRole(role, address(0));
        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
        }
        console.log("");

        openEdition.grantRole(role, address(6));
        roleMemberCount = openEdition.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(openEdition.getRoleMember(role, i));
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        openEdition.claim(receiver, 1, address(0), 0, alp, "");

        // revoke transfer role from address(0)
        vm.prank(deployer);
        openEdition.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.startPrank(receiver);
        vm.expectRevert(("!Transfer-Role"));
        openEdition.transferFrom(receiver, address(123), 1);
    }

    /**
     *  @dev Tests whether role member count is incremented correctly.
     */
    function test_member_count_incremented_properly_when_role_granted() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);
        uint256 roleMemberCount = openEdition.getRoleMemberCount(role);

        assertEq(roleMemberCount, 0);

        openEdition.grantRole(role, receiver);

        assertEq(openEdition.getRoleMemberCount(role), 1);

        vm.stopPrank();
    }

    function test_claimCondition_with_startTimestamp() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].startTimestamp = 100;
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.warp(99);
        vm.prank(getActor(5), getActor(5));
        vm.expectRevert("!CONDITION.");
        openEdition.claim(receiver, 1, address(0), 0, alp, "");

        vm.warp(100);
        vm.prank(getActor(4), getActor(4));
        openEdition.claim(receiver, 1, address(0), 0, alp, "");
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
        openEdition.setSharedMetadata(sharedMetadata);

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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 100, address(erc20), 0, alp, "");

        string memory uri = openEdition.tokenURI(1);
        assertEq(
            uri,
            NFTMetadataRenderer.createMetadataEdition({
                name: sharedMetadata.name,
                description: sharedMetadata.description,
                imageURI: sharedMetadata.imageURI,
                animationURI: sharedMetadata.animationURI,
                tokenOfEdition: 1
            })
        );
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls setSharedMetadata function.
     */
    function test_revert_setSharedMetadata_MINTER_ROLE() public {
        vm.expectRevert();
        openEdition.setSharedMetadata(sharedMetadata);
    }

    /**
     *  note: Testing event emission; shared metadata set.
     */
    function test_event_setSharedMetadata_SharedMetadataUpdated() public {
        vm.startPrank(deployer);

        vm.expectEmit(true, false, false, true);
        emit SharedMetadataUpdated(
            sharedMetadata.name,
            sharedMetadata.description,
            sharedMetadata.imageURI,
            sharedMetadata.animationURI
        );
        openEdition.setSharedMetadata(sharedMetadata);

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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        openEdition.claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert("!MaxSupply");
        vm.prank(getActor(6), getActor(6));
        openEdition.claim(receiver, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 0, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 101, address(0), 0, alp, "");

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 101, address(0), 0, alp, "");
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 100, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), 100);
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.prank(receiver, receiver);
        vm.expectRevert("!PriceOrCurrency");
        openEdition.claim(receiver, 100, address(erc20), 0, alp, "");

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(openEdition), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 100, address(erc20), 5, alp, "");
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), 100);
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = type(uint256).max;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(openEdition), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 100, address(erc20), 10, alp, "");
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), 100);
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 0;
        alp.pricePerToken = 5;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(openEdition), 10000);

        bytes memory errorQty = "!Qty";
        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 100, address(erc20), 5, alp, ""); // trying to claim more than general limit

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 10, address(erc20), 5, alp, "");
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), 10);
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

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);

        // bytes32[] memory proofs = new bytes32[](0);

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);
        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        openEdition.claim(receiver, x - 5, address(0), 0, alp, "");
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), x - 5);

        bytes memory errorQty = "!Qty";

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        openEdition.claim(receiver, 5, address(0), 0, alp, "");
        assertEq(openEdition.getSupplyClaimedByWallet(openEdition.getActiveClaimConditionId(), receiver), x);

        vm.prank(receiver, receiver);
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 5, address(0), 0, alp, ""); // quantity limit already claimed
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        OpenEditionERC721.AllowlistProof memory alp;
        alp.proof = proofs;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        openEdition.setSharedMetadata(sharedMetadata);

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, false);

        vm.prank(getActor(5), getActor(5));
        openEdition.claim(receiver, 100, address(0), 0, alp, "");

        bytes memory errorQty = "!Qty";

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(errorQty);
        openEdition.claim(receiver, 100, address(0), 0, alp, "");

        vm.prank(deployer);
        openEdition.setClaimConditions(conditions, true);

        vm.prank(getActor(5), getActor(5));
        openEdition.claim(receiver, 100, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            setClaimConditions
    //////////////////////////////////////////////////////////////*/

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 currentStartId = 0;
        uint256 count = 0;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        openEdition.setClaimConditions(conditions, false);
        (currentStartId, count) = openEdition.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        openEdition.setClaimConditions(conditions, false);
        (currentStartId, count) = openEdition.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        openEdition.setClaimConditions(conditions, true);
        (currentStartId, count) = openEdition.claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        openEdition.setClaimConditions(conditions, true);
        (currentStartId, count) = openEdition.claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 activeConditionId = 0;

        OpenEditionERC721.ClaimCondition[] memory conditions = new OpenEditionERC721.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerWallet = 12;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerWallet = 22;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerWallet = 32;
        openEdition.setClaimConditions(conditions, false);

        vm.expectRevert("!CONDITION.");
        openEdition.getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = openEdition.getActiveClaimConditionId();
        assertEq(activeConditionId, 0);
        assertEq(openEdition.getClaimConditionById(activeConditionId).startTimestamp, 10);
        assertEq(openEdition.getClaimConditionById(activeConditionId).maxClaimableSupply, 11);
        assertEq(openEdition.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 12);

        vm.warp(20);
        activeConditionId = openEdition.getActiveClaimConditionId();
        assertEq(activeConditionId, 1);
        assertEq(openEdition.getClaimConditionById(activeConditionId).startTimestamp, 20);
        assertEq(openEdition.getClaimConditionById(activeConditionId).maxClaimableSupply, 21);
        assertEq(openEdition.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 22);

        vm.warp(30);
        activeConditionId = openEdition.getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        assertEq(openEdition.getClaimConditionById(activeConditionId).startTimestamp, 30);
        assertEq(openEdition.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        assertEq(openEdition.getClaimConditionById(activeConditionId).quantityLimitPerWallet, 32);

        vm.warp(40);
        assertEq(openEdition.getActiveClaimConditionId(), 2);
    }
}
