// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SignatureDrop } from "contracts/signature-drop/SignatureDrop.sol";
import { ISignatureMintERC721 } from "contracts/feature/interface/ISignatureMintERC721.sol";

// Test imports
import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SignatureDropTest is BaseTest {

    using StringsUpgradeable for uint256;

    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 index, string revealedURI);

    SignatureDrop public sigdrop;
    address internal deployerSigner;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehasEip712;
    bytes32 internal domainSeparator;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        sigdrop = SignatureDrop(getContract("SignatureDrop"));

        erc20.mint(deployerSigner, 1_000_000);
        vm.deal(deployerSigner, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        typehasEip712 = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        domainSeparator = keccak256(abi.encode(typehasEip712, nameHash, versionHash, block.chainid, sigdrop.sigMint()));
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
        bytes memory encryptedBaseURI = "";

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, encryptedBaseURI);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for(uint256 i = 0; i < amountToLazyMint; i += 1) {
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

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, encryptedBaseURI);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        for(uint256 i = 0; i < amountToLazyMint; i += 1) {
            string memory uri = sigdrop.tokenURI(1);
            assertEq(uri, string(abi.encodePacked(baseURI, "0")));
        }

        vm.stopPrank();
    }

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls lazyMint function.
     */
    function test_revert_lazyMint_MINTER_ROLE() public {
        bytes memory errorMessage = abi.encodePacked(
            "Permissions: account ",
            Strings.toHexString(uint160(address(this)), 20),
            " is missing role ",
            Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
        );

        vm.expectRevert(errorMessage);
        sigdrop.lazyMint(100, "ipfs://", "");
    }

    /*
     *  note: Testing revert condition; calling tokenURI for invalid batch id.
     */
    function test_revert_lazyMint_URIForNonLazyMintedToken() public {
        vm.startPrank(deployerSigner);

        sigdrop.lazyMint(100, "ipfs://", "");

        vm.expectRevert("No batch id for token.");
        sigdrop.tokenURI(100);

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; tokens lazy minted.
     */
    function test_event_lazyMint_TokensLazyMinted() public {
        vm.startPrank(deployerSigner);

        vm.expectEmit(false, false, false, true);
        emit TokensLazyMinted(0, 100, "ipfs://", "");
        sigdrop.lazyMint(100, "ipfs://", "");

        vm.stopPrank();
    }

    /*
     *  note: Fuzz testing state changes; lazy mint a batch of tokens with no encrypted base URI.
     */
    function test_fuzz_lazyMint_noEncryptedURI(uint256 x) public {

        vm.assume(x > 0);

        uint256 amountToLazyMint = x;
        string memory baseURI = "ipfs://";
        bytes memory encryptedBaseURI = "";

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, encryptedBaseURI);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = sigdrop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, uint(0).toString())));

        uri = sigdrop.tokenURI(x-1);
        assertEq(uri, string(abi.encodePacked(baseURI, uint(x-1).toString())));

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

        uint256 nextTokenIdToMintBefore = sigdrop.nextTokenIdToMint();

        vm.startPrank(deployerSigner);
        uint256 batchId = sigdrop.lazyMint(amountToLazyMint, baseURI, encryptedBaseURI);

        assertEq(nextTokenIdToMintBefore + amountToLazyMint, sigdrop.nextTokenIdToMint());
        assertEq(nextTokenIdToMintBefore + amountToLazyMint, batchId);

        string memory uri = sigdrop.tokenURI(0);
        assertEq(uri, string(abi.encodePacked(baseURI, "0")));

        uri = sigdrop.tokenURI(x-1);
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

    /*///////////////////////////////////////////////////////////////
                                Delayed Reveal Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; an address without MINTER_ROLE calls reveal function.
     */
    function test_revert_delayedReveal_minterRole() public {
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "", encryptedURI);

        vm.prank(deployerSigner);
        sigdrop.reveal(0, "key");

        bytes memory errorMessage = abi.encodePacked(
            "Permissions: account ",
            Strings.toHexString(uint160(address(this)), 20),
            " is missing role ",
            Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
        );

        vm.expectRevert(errorMessage);
        sigdrop.reveal(0, "key");
    }

    /*
     *  note: Testing revert condition; trying to reveal URI for non-existent batch.
     */
    function test_revert_delayedReveal_getBatchIdAtIndex() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        sigdrop.lazyMint(100, "", encryptedURI);
        sigdrop.reveal(0, "key");

        sigdrop.lazyMint(100, "", encryptedURI);
        vm.expectRevert("invalid index.");
        sigdrop.reveal(2, "key");

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; URI revealed for a batch of tokens.
     */
    function test_state_delayedReveal_getRevealURI() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        sigdrop.lazyMint(100, "", encryptedURI);

        string memory revealedURI = sigdrop.reveal(0, "key");
        assertEq(revealedURI, "ipfs://");

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; revealing URI with an incorrect key.
     */
    function testFail_delayedReveal_incorrectKey() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        sigdrop.lazyMint(100, "", encryptedURI);

        string memory revealedURI = sigdrop.reveal(0, "keyy");
        assertEq(revealedURI, "ipfs://");

        vm.stopPrank();
    }

    /*
     *  note: Testing state changes; check baseURI after reveal for a batch of tokens.
     */
    function test_state_delayedReveal_setBaseURI() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        sigdrop.lazyMint(100, "", encryptedURI);
        sigdrop.reveal(0, "key");

        string memory uri = sigdrop.tokenURI(1);
        assertEq(uri, "ipfs://1");

        vm.stopPrank();
    }

    /**
     *  note: Testing event emission; token URI revealed.
     */
    function test_event_delayedReveal_event() public {
        vm.startPrank(deployerSigner);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        sigdrop.lazyMint(100, "", encryptedURI);

        vm.expectEmit(false, false, false, true);
        emit TokenURIRevealed(0, "ipfs://");
        sigdrop.reveal(0, "key");

        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                Signature Mint Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing revert condition; invalid signature.
     */
    function test_revert_mintWithSignature_processRequestAndRecoverSigner() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");
        uint256 id = 0;

        ISignatureMintERC721.MintRequest memory mintrequest;
        mintrequest.to = address(0);
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
        vm.warp(1000);
        sigdrop.mintWithSignature(mintrequest, signature);

        (v, r, s) = vm.sign(4321, typedDataHash);
        signature = abi.encodePacked(r, s, v);
        vm.expectRevert("Invalid request");
        sigdrop.mintWithSignature(mintrequest, signature);
    }

    /*
     *  note: Testing state changes; minting with signature, for a given price and currency.
     */
    function test_state_mintWithSignature_priceAndCurrency() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");
        uint256 id = 0;
        ISignatureMintERC721.MintRequest memory mintrequest;

        mintrequest.to = address(0);
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
            vm.startPrank(deployerSigner);
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();
        }

        {
            mintrequest.currency = address(NATIVE_TOKEN);
            id = 1;
            mintrequest.uid = bytes32(id);
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
            vm.startPrank(address(deployerSigner));
            vm.warp(1000);
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
            vm.stopPrank();
        }
    }

    /**
     *  note: Testing token balances; checking balance and owner of tokens after minting with signature.
     */
    function test_balances_mintWithSignature_checkBalanceAndOwner() public {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");
        uint256 id = 0;
        ISignatureMintERC721.MintRequest memory mintrequest;

        mintrequest.to = address(0);
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
            vm.startPrank(deployerSigner);
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();

            uint256 balance = sigdrop.balanceOf(address(deployerSigner));
            assertEq(balance, 1);

            address owner = sigdrop.ownerOf(0);
            assertEq(deployerSigner, owner);

            vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
            owner = sigdrop.ownerOf(1);
        }
    }

    /*
     *  note: Testing state changes; minting with signature, for a given price and currency.
     */
    function mintWithSignature_priceAndCurrency(ISignatureMintERC721.MintRequest memory mintrequest) internal {
        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");
        uint256 id = 0;

        {
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
            vm.startPrank(address(deployerSigner));
            vm.warp(mintrequest.validityStartTimestamp);
            sigdrop.mintWithSignature{ value: mintrequest.pricePerToken }(mintrequest, signature);
            vm.stopPrank();
        }
    }

    function test_fuzz_mintWithSignature_priceAndCurrency(uint128 x, uint128 y) public {
        if (x < y) {
            uint256 id = 0;
            ISignatureMintERC721.MintRequest memory mintrequest;

            mintrequest.to = address(0);
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

            mintWithSignature_priceAndCurrency(mintrequest);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Testing state changes; check startId and count after setting claim conditions.
     */
    function test_state_claimCondition_startIdAndCount() public {
        vm.startPrank(deployerSigner);

        uint256 currentStartId = 0;
        uint256 count = 0;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](2);
        conditions[0].startTimestamp = 0;
        conditions[0].maxClaimableSupply = 10;
        conditions[1].startTimestamp = 1;
        conditions[1].maxClaimableSupply = 10;

        sigdrop.setClaimConditions(conditions, false, "");
        (currentStartId, count) = sigdrop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        sigdrop.setClaimConditions(conditions, false, "");
        (currentStartId, count) = sigdrop.claimCondition();
        assertEq(currentStartId, 0);
        assertEq(count, 2);

        sigdrop.setClaimConditions(conditions, true, "");
        (currentStartId, count) = sigdrop.claimCondition();
        assertEq(currentStartId, 2);
        assertEq(count, 2);

        sigdrop.setClaimConditions(conditions, true, "");
        (currentStartId, count) = sigdrop.claimCondition();
        assertEq(currentStartId, 4);
        assertEq(count, 2);
    }

    /**
     *  note: Testing state changes; check activeConditionId based on changes in block timestamp.
     */
    function test_state_claimCondition_startPhase() public {
        vm.startPrank(deployerSigner);

        uint256 activeConditionId = 0;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](3);
        conditions[0].startTimestamp = 10;
        conditions[0].maxClaimableSupply = 11;
        conditions[0].quantityLimitPerTransaction = 12;
        conditions[0].waitTimeInSecondsBetweenClaims = 13;
        conditions[1].startTimestamp = 20;
        conditions[1].maxClaimableSupply = 21;
        conditions[1].quantityLimitPerTransaction = 22;
        conditions[1].waitTimeInSecondsBetweenClaims = 23;
        conditions[2].startTimestamp = 30;
        conditions[2].maxClaimableSupply = 31;
        conditions[2].quantityLimitPerTransaction = 32;
        conditions[2].waitTimeInSecondsBetweenClaims = 33;
        sigdrop.setClaimConditions(conditions, false, "");

        vm.expectRevert("!CONDITION.");
        sigdrop.getActiveClaimConditionId();

        vm.warp(10);
        activeConditionId = sigdrop.getActiveClaimConditionId();
        assertEq(activeConditionId, 0);

        vm.warp(20);
        activeConditionId = sigdrop.getActiveClaimConditionId();
        assertEq(activeConditionId, 1);

        vm.warp(30);
        activeConditionId = sigdrop.getActiveClaimConditionId();
        assertEq(activeConditionId, 2);
        // assertEq(sigdrop.getClaimConditionById(activeConditionId).startTimestamp, 30);
        // assertEq(sigdrop.getClaimConditionById(activeConditionId).maxClaimableSupply, 31);
        // assertEq(sigdrop.getClaimConditionById(activeConditionId).quantityLimitPerTransaction, 32);
        // assertEq(sigdrop.getClaimConditionById(activeConditionId).waitTimeInSecondsBetweenClaims, 33);

        vm.warp(40);
        assertEq(sigdrop.getActiveClaimConditionId(), 2);
    }

    /**
     *  note: Testing revert condition; not allowed to claim again before wait time is over.
     */
    function test_revert_claimCondition_waitTimeInSecondsBetweenClaims() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");
        vm.prank(deployerSigner);
        sigdrop.setClaimConditions(conditions, false, "");

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        vm.expectRevert("cannot claim.");
        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    }

    /**
     *  note: Testing state changes; reset eligibility of claim conditions and claiming again for same condition id.
     */
    function test_state_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(deployerSigner);
        sigdrop.lazyMint(100, "ipfs://", "");

        vm.prank(deployer);
        sigdrop.setClaimConditions(conditions, false, "");

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        vm.prank(deployer);
        sigdrop.setClaimConditions(conditions, true, "");

        vm.prank(getActor(5), getActor(5));
        sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    }
}
