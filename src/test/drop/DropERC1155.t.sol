// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, BatchMintMetadata, Drop1155, LazyMint, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports

import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC1155Test is BaseTest {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    DropERC1155 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC1155(getContract("DropERC1155"));

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
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, caller, role));

        drop.renounceRole(role, caller);
    }

    /**
     *  note: Tests whether contract reverts when a role admin revokes a role for a non-holder.
     */
    function test_revert_revokeRoleForNonHolder() public {
        address target = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, target, role));

        drop.revokeRole(role, target);
    }

    /**
     *  @dev Tests whether contract reverts when a role is granted to an existent role holder.
     */
    function test_revert_grant_role_to_account_with_role() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);

        drop.grantRole(role, receiver);

        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsAlreadyGranted.selector, receiver, role));
        drop.grantRole(role, receiver);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_grant_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        // check if admin and address(0) have transfer role in the beginning
        bool checkAddressZero = drop.hasRole(role, address(0));
        bool checkAdmin = drop.hasRole(role, deployer);
        assertTrue(checkAddressZero);
        assertTrue(checkAdmin);

        // check if transfer role can be granted to a non-holder
        address receiver = getActor(0);
        vm.startPrank(deployer);
        drop.grantRole(role, receiver);

        // expect revert when granting to a holder
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsAlreadyGranted.selector, receiver, role));
        drop.grantRole(role, receiver);

        // check if receiver has transfer role
        bool checkReceiver = drop.hasRole(role, receiver);
        assertTrue(checkReceiver);

        // check if role is correctly revoked
        drop.revokeRole(role, receiver);
        checkReceiver = drop.hasRole(role, receiver);
        assertFalse(checkReceiver);
        drop.revokeRole(role, address(0));
        checkAddressZero = drop.hasRole(role, address(0));
        assertFalse(checkAddressZero);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_getRoleMember_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        uint256 roleMemberCount = drop.getRoleMemberCount(role);
        assertEq(roleMemberCount, 2);

        address roleMember = drop.getRoleMember(role, 1);
        assertEq(roleMember, address(0));

        vm.startPrank(deployer);
        drop.grantRole(role, address(2));
        drop.grantRole(role, address(3));
        drop.grantRole(role, address(4));

        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");

        drop.revokeRole(role, address(2));
        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");

        drop.revokeRole(role, address(0));
        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");

        drop.grantRole(role, address(5));
        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");

        drop.grantRole(role, address(0));
        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");

        drop.grantRole(role, address(6));
        roleMemberCount = drop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(drop.getRoleMember(role, i));
        }
        console.log("");
    }

    /**
     *  note: Testing transfer of tokens when transfer-role is restricted
     */
    function test_claim_transferRole() public {
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, _tokenId, 1, address(0), 0, alp, "");

        // revoke transfer role from address(0)
        vm.prank(deployer);
        drop.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.startPrank(receiver);
        vm.expectRevert("restricted to TRANSFER_ROLE holders.");
        drop.safeTransferFrom(receiver, address(123), 0, 0, "");
    }

    /**
     *  @dev Tests whether role member count is incremented correctly.
     */
    function test_member_count_incremented_properly_when_role_granted() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployer);
        uint256 roleMemberCount = drop.getRoleMemberCount(role);

        assertEq(roleMemberCount, 0);

        drop.grantRole(role, receiver);

        assertEq(drop.getRoleMemberCount(role), 1);

        vm.stopPrank();
    }

    function test_claimCondition_with_startTimestamp() public {
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].startTimestamp = 100;
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.warp(99);
        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropNoActiveCondition.selector));
        drop.claim(receiver, _tokenId, 1, address(0), 0, alp, "");

        vm.warp(100);
        vm.prank(getActor(4), getActor(4));
        drop.claim(receiver, _tokenId, 1, address(0), 0, alp, "");
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
            string memory uri = drop.uri(i);
            console.log(uri);
            assertEq(uri, string(abi.encodePacked(baseURI, i.toString())));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls lazyMint function.
     */
    function test_revert_lazyMint_MINTER_ROLE() public {
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintUnauthorized.selector));
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    /*
     *  note: Testing revert condition; calling tokenURI for invalid batch id.
     */
    function test_revert_lazyMint_URIForNonLazyMintedToken() public {
        vm.startPrank(deployer);

        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidTokenId.selector, 100));
        drop.uri(100);

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

        string memory uri = drop.uri(0);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(0).toString())));

        uri = drop.uri(x - 1);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(x - 1).toString())));

        /**
         *  note: this loop takes too long to run with fuzz tests.
         */
        // for(uint256 i = 0; i < amountToLazyMint; i += 1) {
        //     string memory uri = drop.uri(i);
        //     console.log(uri);
        //     assertEq(uri, string(abi.encodePacked(baseURI, i.toString())));
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
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; not enough minted tokens.
     */
    function test_revert_claimCondition_notEnoughMintedTokens() public {
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        drop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropNoActiveCondition.selector));
        vm.prank(getActor(6), getActor(6));
        drop.claim(receiver, 100, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing revert condition; exceed max claimable supply.
     */
    function test_revert_claimCondition_exceedMaxClaimableSupply() public {
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 200;

        vm.prank(deployer);
        drop.lazyMint(200, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, _tokenId, 100, address(0), 0, alp, "");

        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedMaxSupply.selector, 100, 101));
        vm.prank(getActor(6), getActor(6));
        drop.claim(receiver, _tokenId, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, 100, 0));
        drop.claim(receiver, _tokenId, 0, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, 100, 101));
        drop.claim(receiver, _tokenId, 101, address(0), 0, alp, "");

        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, 100, 101));
        drop.claim(receiver, _tokenId, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price set to 0
     */
    function test_state_claim_allowlisted_SetQuantityZeroPrice() public {
        uint256 _tokenId = 0;
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

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, 100, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), 100);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price set to non-zero value
     */
    function test_state_claim_allowlisted_SetQuantityPrice() public {
        uint256 _tokenId = 0;
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

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 5;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(receiver, receiver);
        vm.expectRevert(
            abi.encodeWithSelector(Drop1155.DropClaimInvalidTokenPrice.selector, address(erc20), 0, address(erc20), 5)
        );
        drop.claim(receiver, _tokenId, 100, address(erc20), 0, alp, "");

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, 100, address(erc20), 5, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), 100);
        assertEq(erc20.balanceOf(receiver), 10000 - 500);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to some value different than general limit
     *          - allowlist price not set; should default to general price and currency
     */
    function test_state_claim_allowlisted_SetQuantityDefaultPrice() public {
        uint256 _tokenId = 0;
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

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = type(uint256).max;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, 100, address(erc20), 10, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), 100);
        assertEq(erc20.balanceOf(receiver), 10000 - 1000);
    }

    /**
     *  note: Testing quantity limit restriction
     *          - allowlist quantity set to 0 => should default to general limit
     *          - allowlist price set to some value different than general price
     */
    function test_state_claim_allowlisted_DefaultQuantitySomePrice() public {
        uint256 _tokenId = 0;
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

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 0;
        alp.pricePerToken = 5;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        erc20.mint(receiver, 10000);
        vm.prank(receiver);
        erc20.approve(address(drop), 10000);

        vm.prank(receiver, receiver);
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, 10, 100));
        drop.claim(receiver, _tokenId, 100, address(erc20), 5, alp, ""); // trying to claim more than general limit

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, 10, address(erc20), 5, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), 10);
        assertEq(erc20.balanceOf(receiver), 10000 - 50);
    }

    function test_fuzz_claim_merkleProof(uint256 x) public {
        vm.assume(x > 10 && x < 500);
        uint256 _tokenId = 0;
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

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        // bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        vm.prank(deployer);
        drop.lazyMint(2 * x, "ipfs://", emptyEncodedBytes);
        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, x - 5, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), x - 5);

        vm.prank(receiver, receiver);
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, x, x + 1));
        drop.claim(receiver, _tokenId, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        drop.claim(receiver, _tokenId, 5, address(0), 0, alp, "");
        assertEq(drop.getSupplyClaimedByWallet(_tokenId, drop.getActiveClaimConditionId(_tokenId), receiver), x);

        vm.prank(receiver, receiver);
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, x, x + 5));
        drop.claim(receiver, _tokenId, 5, address(0), 0, alp, ""); // quantity limit already claimed
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility() public {
        vm.warp(1);

        uint256 _tokenId = 0;
        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        DropERC1155.AllowlistProof memory alp;
        alp.proof = proofs;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployer);
        drop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, _tokenId, 100, address(0), 0, alp, "");

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropClaimExceedLimit.selector, 100, 200));
        drop.claim(receiver, _tokenId, 100, address(0), 0, alp, "");

        vm.prank(deployer);
        drop.setClaimConditions(_tokenId, conditions, true);

        vm.prank(getActor(5), getActor(5));
        drop.claim(receiver, _tokenId, 100, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            setClaimConditions
    //////////////////////////////////////////////////////////////*/

    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer);

        uint256 _tokenId = 0;
        uint256 currentStartId = 0;
        uint256 count = 0;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        drop.setClaimConditions(_tokenId, conditions, false);
        (currentStartId, count) = drop.claimCondition(_tokenId);
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(_tokenId, conditions, false);
        (currentStartId, count) = drop.claimCondition(_tokenId);
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        drop.setClaimConditions(_tokenId, conditions, true);
        (currentStartId, count) = drop.claimCondition(_tokenId);
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        drop.setClaimConditions(_tokenId, conditions, true);
        (currentStartId, count) = drop.claimCondition(_tokenId);
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer);

        uint256 _tokenId = 0;
        uint256 activeConditionId = 0;

        DropERC1155.ClaimCondition[] memory conditions = new DropERC1155.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerWallet = 12;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerWallet = 22;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerWallet = 32;
        drop.setClaimConditions(_tokenId, conditions, false);

        vm.expectRevert(abi.encodeWithSelector(Drop1155.DropNoActiveCondition.selector));
        drop.getActiveClaimConditionId(_tokenId);

        vm.warp(10);
        activeConditionId = drop.getActiveClaimConditionId(_tokenId);
        assertEq(activeConditionId, 0);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).startTimestamp, 10);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).maxClaimableSupply, 11);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).quantityLimitPerWallet, 12);

        vm.warp(20);
        activeConditionId = drop.getActiveClaimConditionId(_tokenId);
        assertEq(activeConditionId, 1);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).startTimestamp, 20);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).maxClaimableSupply, 21);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).quantityLimitPerWallet, 22);

        vm.warp(30);
        activeConditionId = drop.getActiveClaimConditionId(_tokenId);
        assertEq(activeConditionId, 2);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).startTimestamp, 30);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).maxClaimableSupply, 31);
        assertEq(drop.getClaimConditionById(_tokenId, activeConditionId).quantityLimitPerWallet, 32);

        vm.warp(40);
        assertEq(drop.getActiveClaimConditionId(_tokenId), 2);
    }

    /*///////////////////////////////////////////////////////////////
                    Unit Test: updateBatchBaseURI
    //////////////////////////////////////////////////////////////*/

    function test_state_updateBatchBaseURI() public {
        string memory initURI = "ipfs://init";
        string memory newURI = "ipfs://new";

        vm.startPrank(deployer);
        drop.lazyMint(100, initURI, "");

        string memory initTokenURI = drop.uri(0);

        assertEq(initTokenURI, string(abi.encodePacked(initURI, "0")));

        drop.updateBatchBaseURI(0, newURI);

        string memory newTokenURI = drop.uri(0);

        assertEq(newTokenURI, string(abi.encodePacked(newURI, "0")));
    }

    /*///////////////////////////////////////////////////////////////
                    Unit Test: freezeBatchBaseURI
    //////////////////////////////////////////////////////////////*/

    function test_state_freezeBatchBaseURI() public {
        string memory initURI = "ipfs://init";

        vm.startPrank(deployer);
        drop.lazyMint(100, initURI, "");

        string memory initTokenURI = drop.uri(0);

        assertEq(initTokenURI, string(abi.encodePacked(initURI, "0")));

        drop.freezeBatchBaseURI(0);

        assertEq(drop.batchFrozen(100), true);
    }

    /*///////////////////////////////////////////////////////////////
                    Unit Test: setMaxTotalSupply
    //////////////////////////////////////////////////////////////*/

    function test_state_setMaxTotalSupply() public {
        vm.startPrank(deployer);
        drop.setMaxTotalSupply(1, 100);

        assertEq(drop.maxTotalSupply(1), 100);
    }

    function test_event_setMaxTotalSupply_MaxTotalSupplyUpdated() public {
        vm.startPrank(deployer);

        vm.expectEmit(true, false, false, true);
        emit MaxTotalSupplyUpdated(1, 100);
        drop.setMaxTotalSupply(1, 100);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/
}
