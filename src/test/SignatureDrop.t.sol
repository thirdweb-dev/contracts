// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SignatureDrop, DropSinglePhase, Permissions, LazyMint, BatchMintMetadata, DelayedReveal, IDropSinglePhase, IDelayedReveal, ISignatureMintERC721, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/signature-drop/SignatureDrop.sol";
import { SignatureMintERC721 } from "contracts/extension/SignatureMintERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "./utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SignatureDropTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        SignatureDrop.MintRequest mintRequest
    );

    SignatureDrop public sigdrop;
    address internal deployerSigner;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        sigdrop = SignatureDrop(getContract("SignatureDrop"));

        erc20.mint(deployerSigner, 1_000 ether);
        vm.deal(deployerSigner, 1_000 ether);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(sigdrop)));
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
        vm.expectRevert();

        sigdrop.renounceRole(role, caller);
    }

    /**
     *  note: Tests whether contract reverts when a role admin revokes a role for a non-holder.
     */
    function test_revert_revokeRoleForNonHolder() public {
        address target = address(0x123);
        bytes32 role = keccak256("MINTER_ROLE");

        vm.prank(deployerSigner);
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsUnauthorizedAccount.selector, target, role));

        sigdrop.revokeRole(role, target);
    }

    /**
     *  @dev Tests whether contract reverts when a role is granted to an existent role holder.
     */
    function test_revert_grant_role_to_account_with_role() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployerSigner);

        sigdrop.grantRole(role, receiver);

        vm.expectRevert();
        sigdrop.grantRole(role, receiver);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_grant_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        // check if admin and address(0) have transfer role in the beginning
        bool checkAddressZero = sigdrop.hasRole(role, address(0));
        bool checkAdmin = sigdrop.hasRole(role, deployerSigner);
        assertTrue(checkAddressZero);
        assertTrue(checkAdmin);

        // check if transfer role can be granted to a non-holder
        address receiver = getActor(0);
        vm.startPrank(deployerSigner);
        sigdrop.grantRole(role, receiver);

        // expect revert when granting to a holder
        vm.expectRevert(abi.encodeWithSelector(Permissions.PermissionsAlreadyGranted.selector, receiver, role));
        sigdrop.grantRole(role, receiver);

        // check if receiver has transfer role
        bool checkReceiver = sigdrop.hasRole(role, receiver);
        assertTrue(checkReceiver);

        // check if role is correctly revoked
        sigdrop.revokeRole(role, receiver);
        checkReceiver = sigdrop.hasRole(role, receiver);
        assertFalse(checkReceiver);
        sigdrop.revokeRole(role, address(0));
        checkAddressZero = sigdrop.hasRole(role, address(0));
        assertFalse(checkAddressZero);

        vm.stopPrank();
    }

    /**
     *  @dev Tests contract state for Transfer role.
     */
    function test_state_getRoleMember_transferRole() public {
        bytes32 role = keccak256("TRANSFER_ROLE");

        uint256 roleMemberCount = sigdrop.getRoleMemberCount(role);
        assertEq(roleMemberCount, 2);

        address roleMember = sigdrop.getRoleMember(role, 1);
        assertEq(roleMember, address(0));

        vm.startPrank(deployerSigner);
        sigdrop.grantRole(role, address(2));
        sigdrop.grantRole(role, address(3));
        sigdrop.grantRole(role, address(4));

        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
        }
        console.log("");

        sigdrop.revokeRole(role, address(2));
        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
        }
        console.log("");

        sigdrop.revokeRole(role, address(0));
        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
        }
        console.log("");

        sigdrop.grantRole(role, address(5));
        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
        }
        console.log("");

        sigdrop.grantRole(role, address(0));
        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
        }
        console.log("");

        sigdrop.grantRole(role, address(6));
        roleMemberCount = sigdrop.getRoleMemberCount(role);
        console.log(roleMemberCount);
        for (uint256 i = 0; i < roleMemberCount; i++) {
            console.log(sigdrop.getRoleMember(role, i));
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

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        // revoke transfer role from address(0)
        vm.prank(deployerSigner);
        sigdrop.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.startPrank(receiver);
        vm.expectRevert("!Transfer-Role");
        sigdrop.transferFrom(receiver, address(123), 0);
    }

    /**
     *  @dev Tests whether role member count is incremented correctly.
     */
    function test_member_count_incremented_properly_when_role_granted() public {
        bytes32 role = keccak256("ABC_ROLE");
        address receiver = getActor(0);

        vm.startPrank(deployerSigner);
        uint256 roleMemberCount = sigdrop.getRoleMemberCount(role);

        assertEq(roleMemberCount, 0);

        sigdrop.grantRole(role, receiver);

        assertEq(sigdrop.getRoleMemberCount(role), 1);

        vm.stopPrank();
    }

    function test_claimCondition_with_startTimestamp() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].startTimestamp = 100;
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.warp(100);
        vm.prank(getActor(4), getActor(4));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        vm.warp(99);
        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimNotStarted.selector,
                conditions[0].startTimestamp,
                block.timestamp
            )
        );
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");
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

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, emptyEncodedBytes);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = sigdrop.tokenURI(i);
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

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = sigdrop.tokenURI(1);
            assertEq(uri, string(abi.encodePacked(baseURI, "0")));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls lazyMint function.
     */
    function test_revert_lazyMint_MINTER_ROLE() public {
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        vm.prank(deployerSigner);
        sigdrop.grantRole(_minterRole, address(0x345));

        vm.prank(address(0x345));
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(address(0x567));
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintUnauthorized.selector));
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    /*
     *  note: Testing revert condition; calling tokenURI for invalid batch id.
     */
    function test_revert_lazyMint_URIForNonLazyMintedToken() public {
        vm.startPrank(deployerSigner);

        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidTokenId.selector, 100));
        sigdrop.tokenURI(100);

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; tokens lazy minted.
     */
    function test_event_lazyMint_TokensLazyMinted() public {
        vm.startPrank(deployerSigner);

        vm.expectEmit(true, false, false, true);
        emit TokensLazyMinted(0, 99, "ipfs://", emptyEncodedBytes);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing state changes; lazy mint a batch of tokens with no encrypted base URI.
     */
    function test_fuzz_lazyMint_noEncryptedURI(uint256 x) public {
        vm.assume(x > 0);

        uint256 amountToLazyMint = x;
        string memory baseURI = "ipfs://";

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, emptyEncodedBytes);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = sigdrop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(0).toString())));

        uri = sigdrop.tokenURI(x - 1);
        assertEq(uri, string(abi.encodePacked(baseURI, uint256(x - 1).toString())));

        /**
         *  note: this loop takes too long to run with fuzz tests.
         */
        // for(uint256 i = 0; i < amountToLazyMint; i += 1) {
        //     string memory uri = sigdrop.tokenURI(i);
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

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = sigdrop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, "0")));

        uri = sigdrop.tokenURI(x - 1);
        assertEq(uri, string(abi.encodePacked(baseURI, "0")));

        /**
         *  note: this loop takes too long to run with fuzz tests.
         */
        // for(uint256 i = 0; i < amountToLazyMint; i += 1) {
        //     string memory uri = sigdrop.tokenURI(1);
        //     assertEq(uri, string(abi.encodePacked(baseURI, "0")));
        // }

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing; a batch of tokens, and nextTokenIdToMint
     */
    function test_fuzz_lazyMint_batchMintAndNextTokenIdToMint(uint256 x) public {
        vm.assume(x > 0);
        vm.startPrank(deployerSigner);

        if (x == 0) {
            vm.expectRevert("Zero amount");
        }
        sigdrop.lazyMint(x, "ipfs://", emptyEncodedBytes);

        uint256 slot = stdstore.target(address(sigdrop)).sig("nextTokenIdToMint()").find();
        bytes32 loc = bytes32(slot);
        uint256 nextTokenIdToMint = uint256(vm.load(address(sigdrop), loc));

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
        vm.startPrank(deployerSigner);

        bytes memory key = "key";
        uint256 amountToLazyMint = 100;
        bytes memory secretURI = "ipfs://";
        string memory placeholderURI = "ipfs://";
        bytes memory encryptedURI = sigdrop.encryptDecrypt(secretURI, key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        sigdrop.lazyMint(amountToLazyMint, placeholderURI, abi.encode(encryptedURI, provenanceHash));

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = sigdrop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(placeholderURI, "0")));
        }

        string memory revealedURI = sigdrop.reveal(0, key);
        assertEq(revealedURI, string(secretURI));

        for (uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = sigdrop.tokenURI(i);
            assertEq(uri, string(abi.encodePacked(secretURI, i.toString())));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls reveal function.
     */
    function test_revert_reveal_MINTER_ROLE() public {
        bytes memory key = "key";
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        vm.prank(deployerSigner);
        sigdrop.reveal(0, "key");

        vm.expectRevert(
            abi.encodeWithSelector(
                Permissions.PermissionsUnauthorizedAccount.selector,
                address(this),
                keccak256("MINTER_ROLE")
            )
        );
        sigdrop.reveal(0, "key");
    }

    /*
     *  note: Testing revert condition; trying to reveal URI for non-existent batch.
     */
    function test_revert_reveal_revealingNonExistentBatch() public {
        vm.startPrank(deployerSigner);

        bytes memory key = "key";
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        sigdrop.reveal(0, "key");

        console.log(sigdrop.getBaseURICount());

        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        vm.expectRevert(abi.encodeWithSelector(BatchMintMetadata.BatchMintInvalidBatchId.selector, 2));
        sigdrop.reveal(2, "key");

        vm.stopPrank();
    }

    /*
     *  note: Testing revert condition; already revealed URI.
     */
    function test_revert_delayedReveal_alreadyRevealed() public {
        vm.startPrank(deployerSigner);

        bytes memory key = "key";
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        sigdrop.reveal(0, "key");

        vm.expectRevert(abi.encodeWithSelector(DelayedReveal.DelayedRevealNothingToReveal.selector));
        sigdrop.reveal(0, "key");

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; revealing URI with an incorrect key.
     */
    function testFail_reveal_incorrectKey() public {
        vm.startPrank(deployerSigner);

        bytes memory key = "key";
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        string memory revealedURI = sigdrop.reveal(0, "keyy");
        assertEq(revealedURI, "ipfs://");

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; TokenURIRevealed.
     */
    function test_event_reveal_TokenURIRevealed() public {
        vm.startPrank(deployerSigner);

        bytes memory key = "key";
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", key);
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", key, block.chainid));
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));

        vm.expectEmit(true, false, false, true);
        emit TokenURIRevealed(0, "ipfs://");
        sigdrop.reveal(0, "key");

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                        Signature Mint Tests
    //////////////////////////////////////////////////////////////*/

    function signMintRequest(
        SignatureDrop.MintRequest memory mintrequest,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            mintrequest.to,
            mintrequest.royaltyRecipient,
            mintrequest.royaltyBps,
            mintrequest.primarySaleRecipient,
            keccak256(bytes(mintrequest.uri)),
            mintrequest.quantity,
            mintrequest.pricePerToken,
            mintrequest.currency,
            mintrequest.validityStartTimestamp,
            mintrequest.validityEndTimestamp,
            mintrequest.uid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }

    /*
     *  note: Testing state changes; minting with signature, for a given price and currency.
     */
    function test_state_mintWithSignature() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1;
        mintrequest.currency = address(erc20);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        // Test with ERC20 currency
        {
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(deployerSigner);
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1);
            vm.expectEmit(true, true, true, false);
            emit TokensMintedWithSignature(deployerSigner, address(0x567), 0, mintrequest);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());
        }

        // Test with native token currency
        {
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            mintrequest.currency = address(NATIVE_TOKEN);
            id = 1;
            mintrequest.uid = bytes32(id);

            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(address(deployerSigner));
            vm.warp(1000);
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
            vm.stopPrank();

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());
        }
    }

    /*
     *  note: Testing state changes; minting with signature, for a given price and currency.
     */
    function test_state_mintWithSignature_UpdateRoyaltyAndSaleInfo() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(0x567);
        mintrequest.royaltyBps = 100;
        mintrequest.primarySaleRecipient = address(0x567);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1 ether;
        mintrequest.currency = address(erc20);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        // Test with ERC20 currency
        {
            erc20.mint(address(0x345), 1 ether);
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(address(0x345));
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1 ether);
            vm.expectEmit(true, true, true, true);
            emit TokensMintedWithSignature(deployerSigner, address(0x567), 0, mintrequest);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());

            (address _royaltyRecipient, uint16 _royaltyBps) = sigdrop.getRoyaltyInfoForToken(0);
            assertEq(_royaltyRecipient, address(0x567));
            assertEq(_royaltyBps, 100);

            uint256 totalPrice = 1 * 1 ether;
            uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
            assertEq(erc20.balanceOf(address(0x567)), totalPrice - platformFees);
        }

        // Test with native token currency
        {
            vm.deal(address(0x345), 1 ether);
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            mintrequest.currency = address(NATIVE_TOKEN);
            id = 1;
            mintrequest.uid = bytes32(id);

            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(address(0x345));
            vm.warp(1000);
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
            vm.stopPrank();

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());

            (address _royaltyRecipient, uint16 _royaltyBps) = sigdrop.getRoyaltyInfoForToken(0);
            assertEq(_royaltyRecipient, address(0x567));
            assertEq(_royaltyBps, 100);

            uint256 totalPrice = 1 * 1 ether;
            uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;
            assertEq(address(0x567).balance, totalPrice - platformFees);
        }
    }

    /**
     *  note: Testing revert condition; invalid signature.
     */
    function test_revert_mintWithSignature_unapprovedSigner() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;

        SignatureDrop.MintRequest memory mintrequest;
        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 0;
        mintrequest.currency = address(3);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        bytes memory signature = signMintRequest(mintrequest, privateKey);
        vm.warp(1000);
        vm.prank(deployerSigner);
        sigdrop.mintWithSignature(mintrequest, signature);

        signature = signMintRequest(mintrequest, 4321);
        vm.expectRevert(abi.encodeWithSelector(SignatureMintERC721.SignatureMintInvalidSigner.selector));
        sigdrop.mintWithSignature(mintrequest, signature);
    }

    /**
     *  note: Testing revert condition; minting zero tokens.
     */
    function test_revert_mintWithSignature_zeroQuantity() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;

        SignatureDrop.MintRequest memory mintrequest;
        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 0;
        mintrequest.pricePerToken = 0;
        mintrequest.currency = address(3);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        bytes memory signature = signMintRequest(mintrequest, privateKey);
        vm.warp(1000);

        vm.prank(deployerSigner);
        vm.expectRevert(abi.encodeWithSelector(SignatureMintERC721.SignatureMintInvalidQuantity.selector));
        sigdrop.mintWithSignature(mintrequest, signature);
    }

    /**
     *  note: Testing revert condition; not enough minted tokens.
     */
    function test_revert_mintWithSignature_notEnoughMintedTokens() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;

        SignatureDrop.MintRequest memory mintrequest;
        mintrequest.to = address(0);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 101;
        mintrequest.pricePerToken = 0;
        mintrequest.currency = address(3);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        bytes memory signature = signMintRequest(mintrequest, privateKey);
        vm.warp(1000);
        vm.expectRevert("!Tokens");
        sigdrop.mintWithSignature(mintrequest, signature);
    }

    /**
     *  note: Testing revert condition; sent value is not equal to price.
     */
    function test_revert_mintWithSignature_notSentAmountRequired() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1;
        mintrequest.currency = address(3);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);
        {
            mintrequest.currency = address(NATIVE_TOKEN);
            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(address(deployerSigner));
            vm.warp(mintrequest.validityStartTimestamp);
            vm.expectRevert("!Price");
            sigdrop.mintWithSignature{ value: 2 }(mintrequest, signature);
            vm.stopPrank();
        }
    }

    /**
     *  note: Testing token balances; checking balance and owner of tokens after minting with signature.
     */
    function test_balances_mintWithSignature() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0x567);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1;
        mintrequest.currency = address(erc20);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        {
            uint256 currencyBalBefore = erc20.balanceOf(deployerSigner);

            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(deployerSigner);
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();

            uint256 balance = sigdrop.balanceOf(address(0x567));
            assertEq(balance, 1);

            address owner = sigdrop.ownerOf(0);
            assertEq(address(0x567), owner);

            assertEq(
                currencyBalBefore - mintrequest.pricePerToken * mintrequest.quantity,
                erc20.balanceOf(deployerSigner)
            );

            vm.expectRevert(abi.encodeWithSelector(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector));
            owner = sigdrop.ownerOf(1);
        }
    }

    /*
     *  note: Testing state changes; minting with signature, for a given price and currency.
     */
    function mintWithSignature(SignatureDrop.MintRequest memory mintrequest) internal {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;

        {
            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(deployerSigner);
            vm.warp(mintrequest.validityStartTimestamp);
            erc20.approve(address(sigdrop), 1);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();
        }

        {
            mintrequest.currency = address(NATIVE_TOKEN);
            id = 1;
            mintrequest.uid = bytes32(id);
            bytes memory signature = signMintRequest(mintrequest, privateKey);
            vm.startPrank(address(deployerSigner));
            vm.warp(mintrequest.validityStartTimestamp);
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
            vm.stopPrank();
        }
    }

    function test_fuzz_mintWithSignature(uint128 x, uint128 y) public {
        if (x < y) {
            uint256 id = 0;
            SignatureDrop.MintRequest memory mintrequest;

            mintrequest.to = address(0x567);
            mintrequest.royaltyRecipient = address(2);
            mintrequest.royaltyBps = 0;
            mintrequest.primarySaleRecipient = address(deployer);
            mintrequest.uri = "ipfs://";
            mintrequest.quantity = 1;
            mintrequest.pricePerToken = 1;
            mintrequest.currency = address(erc20);
            mintrequest.validityStartTimestamp = x;
            mintrequest.validityEndTimestamp = y;
            mintrequest.uid = bytes32(id);

            mintWithSignature(mintrequest);
        }
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

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.expectRevert("!Tokens");
        vm.prank(getActor(6), getActor(6));
        sigdrop.claim(receiver, 101, address(0), 0, alp, "");
    }

    /**
     *  note: Testing revert condition; exceed max claimable supply.
     */
    function test_revert_claimCondition_exceedMaxClaimableSupply() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(200, "ipfs://", emptyEncodedBytes);
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 100, address(0), 0, alp, "");

        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedMaxSupply.selector,
                conditions[0].maxClaimableSupply,
                101
            )
        );
        vm.prank(getActor(6), getActor(6));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing quantity limit restriction when no allowlist present.
     */
    function test_fuzz_claim_noAllowlist(uint256 x) public {
        vm.assume(x != 0);
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(500, "ipfs://", emptyEncodedBytes);

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedLimit.selector,
                conditions[0].quantityLimitPerWallet,
                101
            )
        );
        sigdrop.claim(receiver, 101, address(0), 0, alp, "");

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], true);

        vm.prank(getActor(5), getActor(5));
        vm.expectRevert(
            abi.encodeWithSelector(
                DropSinglePhase.DropClaimExceedLimit.selector,
                conditions[0].quantityLimitPerWallet,
                101
            )
        );
        sigdrop.claim(receiver, 101, address(0), 0, alp, "");
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

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = x;
        alp.pricePerToken = 0;
        alp.currency = address(0);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

        // bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = x;
        conditions[0].quantityLimitPerWallet = 1;
        conditions[0].merkleRoot = root;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(2 * x, "ipfs://", emptyEncodedBytes);
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        sigdrop.claim(receiver, x - 5, address(0), 0, alp, "");
        assertEq(sigdrop.getSupplyClaimedByWallet(receiver), x - 5);

        vm.prank(receiver, receiver);
        vm.expectRevert(abi.encodeWithSelector(DropSinglePhase.DropClaimExceedLimit.selector, x, x + 1));
        sigdrop.claim(receiver, 6, address(0), 0, alp, "");

        vm.prank(receiver, receiver);
        sigdrop.claim(receiver, 5, address(0), 0, alp, "");
        assertEq(sigdrop.getSupplyClaimedByWallet(receiver), x);

        vm.prank(receiver, receiver);
        vm.expectRevert(abi.encodeWithSelector(DropSinglePhase.DropClaimExceedLimit.selector, x, x + 5));
        sigdrop.claim(receiver, 5, address(0), 0, alp, "");
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], true);

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function test_delayedReveal_withNewLazyMintedEmptyBatch() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes32 provenanceHash = keccak256(abi.encodePacked("ipfs://", "key", block.chainid));
        sigdrop.lazyMint(100, "", abi.encode(encryptedURI, provenanceHash));
        sigdrop.reveal(0, "key");

        string memory uri = sigdrop.tokenURI(1);
        assertEq(uri, string(abi.encodePacked("ipfs://", "1")));

        bytes memory newEncryptedURI = sigdrop.encryptDecrypt("ipfs://secret", "key");
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintInvalidAmount.selector));
        sigdrop.lazyMint(0, "", abi.encode(newEncryptedURI, provenanceHash));

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                            Reentrancy related Tests
    //////////////////////////////////////////////////////////////*/

    function testFail_reentrancy_mintWithSignature() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1;
        mintrequest.currency = address(NATIVE_TOKEN);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        // Test with native token currency
        {
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            mintrequest.uid = bytes32(id);
            bytes memory signature = signMintRequest(mintrequest, privateKey);

            MaliciousReceiver mal = new MaliciousReceiver(address(sigdrop));
            vm.deal(address(mal), 100 ether);
            vm.warp(1000);
            mal.attackMintWithSignature(mintrequest, signature, false);

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());
        }
    }

    function testFail_reentrancy_claim() public {
        vm.warp(1);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        MaliciousReceiver mal = new MaliciousReceiver(address(sigdrop));
        vm.deal(address(mal), 100 ether);
        mal.attackClaim(alp, false);
    }

    function testFail_combination_signatureAndClaim() public {
        vm.warp(1);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions[0], false);

        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        mintrequest.to = address(0);
        mintrequest.royaltyRecipient = address(2);
        mintrequest.royaltyBps = 0;
        mintrequest.primarySaleRecipient = address(deployer);
        mintrequest.uri = "ipfs://";
        mintrequest.quantity = 1;
        mintrequest.pricePerToken = 1;
        mintrequest.currency = address(NATIVE_TOKEN);
        mintrequest.validityStartTimestamp = 1000;
        mintrequest.validityEndTimestamp = 2000;
        mintrequest.uid = bytes32(id);

        // Test with native token currency
        {
            uint256 totalSupplyBefore = sigdrop.totalSupply();

            mintrequest.uid = bytes32(id);
            bytes memory signature = signMintRequest(mintrequest, privateKey);

            MaliciousReceiver mal = new MaliciousReceiver(address(sigdrop));
            vm.deal(address(mal), 100 ether);
            vm.warp(1000);
            mal.saveCombination(mintrequest, signature, alp);
            mal.attackMintWithSignature(mintrequest, signature, true);
            // mal.attackClaim(alp, true);

            assertEq(totalSupplyBefore + mintrequest.quantity, sigdrop.totalSupply());
        }
    }
}

contract MaliciousReceiver {
    SignatureDrop public sigdrop;

    SignatureDrop.MintRequest public mintrequest;
    SignatureDrop.AllowlistProof public alp;
    bytes public signature;
    bool public claim;
    bool public loop = true;

    constructor(address _sigdrop) {
        sigdrop = SignatureDrop(_sigdrop);
    }

    function attackMintWithSignature(
        SignatureDrop.MintRequest calldata _mintrequest,
        bytes calldata _signature,
        bool swap
    ) external {
        claim = swap;
        mintrequest = _mintrequest;
        signature = _signature;
        sigdrop.mintWithSignature{ value: _mintrequest.pricePerToken }(_mintrequest, _signature);
    }

    function attackClaim(SignatureDrop.AllowlistProof calldata _alp, bool swap) external {
        claim = !swap;
        alp = _alp;
        sigdrop.claim(address(this), 1, address(0), 0, _alp, "");
    }

    function saveCombination(
        SignatureDrop.MintRequest calldata _mintrequest,
        bytes calldata _signature,
        SignatureDrop.AllowlistProof calldata _alp
    ) external {
        mintrequest = _mintrequest;
        signature = _signature;
        alp = _alp;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        if (claim && loop) {
            loop = false;
            claim = false;
            sigdrop.claim(address(this), 1, address(0), 0, alp, "");
        } else if (!claim && loop) {
            loop = false;
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
        }
        return this.onERC721Received.selector;
    }
}
