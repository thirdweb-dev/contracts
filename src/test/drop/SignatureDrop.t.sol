// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SignatureDrop } from "contracts/drop/SignatureDrop.sol";

// Test imports
import "../utils/BaseTest.sol";

contract SignatureDropTest is BaseTest {
    event TokenLazyMinted(uint256 indexed startId, uint256 amount, string indexed baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 index, string revealedURI);

    SignatureDrop public sigdrop;
    address deployer_signer;
    bytes32 typehash;
    bytes32 nameHash;
    bytes32 versionHash;
    bytes32 _TYPE_HASH;
    bytes32 domainSeparator;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployer_signer = signer;
        sigdrop = SignatureDrop(getContract("SignatureDrop"));

        erc20.mint(deployer_signer, 1_000_000);
        vm.deal(deployer_signer, 1_000);

        typehash =
            keccak256(
                "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
            );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        domainSeparator = keccak256(abi.encode(_TYPE_HASH, nameHash, versionHash, block.chainid, address(sigdrop)));
    }

    /*///////////////////////////////////////////////////////////////
                                Lazy Mint Tests
    //////////////////////////////////////////////////////////////*/

    // - test access/roles
    function test_lazyMint_minterRole() public {
        bytes memory data = abi.encode("", 0);

        vm.prank(deployer_signer);
        sigdrop.lazyMint(100, "ipfs://", data);

        bytes memory errorMessage =
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(address(this)), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
                    );

        vm.expectRevert(errorMessage);
        sigdrop.lazyMint(100, "ipfs://", data);
    }

    // - expect revert when start id not equal to expected id
    function test_lazyMint_StartIdAndExpectedStartId() public {
        vm.startPrank(deployer_signer);

        bytes memory data = abi.encode("", 0);
        sigdrop.lazyMint(100, "ipfs://", data);

        data = abi.encode("", 100);
        sigdrop.lazyMint(100, "ipfs://", data);

        data = abi.encode("", 199);
        vm.expectRevert("Unexpected start Id");
        sigdrop.lazyMint(100, "ipfs://", data);
        
        vm.stopPrank();
    }

    // - test _batchMint and value of nextTokenIdToMint
    function test_lazyMint_batchMintAndNextTokenIdToMint() public {
        vm.startPrank(deployer_signer);

        bytes memory data = abi.encode("", 0);
        sigdrop.lazyMint(100, "ipfs://", data);

        uint256 slot = stdstore.target(address(sigdrop)).sig("nextTokenIdToMint()").find();
        bytes32 loc = bytes32(slot);
        uint256 nextTokenIdToMint = uint256(vm.load(address(sigdrop), loc));

        assertEq(nextTokenIdToMint, 100);
        vm.stopPrank();
    }
    
    // - test _batchMint and tokenURI
    function test_lazyMint_batchMintAndTokenURI() public {
        vm.startPrank(deployer_signer);

        bytes memory data = abi.encode("", 0);
        sigdrop.lazyMint(100, "ipfs://", data);

        string memory uri = sigdrop.tokenURI(1);
        assertEq(uri, "ipfs://1");

        uri = sigdrop.tokenURI(99);
        assertEq(uri, "ipfs://99");

        vm.expectRevert("No base URI for token.");
        uri = sigdrop.tokenURI(100);

        vm.stopPrank();
    }

    // - test _setEncryptedBaseURI and tokenURI
    function test_lazyMint_setEncryptedBaseURIAndTokenURI() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);

        string memory uri = sigdrop.tokenURI(1);
        assertEq(uri, "1");
        /// note: can we return an error message instead? that "no base uri for token." etc.
        /// note: should we check for lengths of baseURI and encryptedURI.. both can't be empty

        vm.stopPrank();
    }

    // - test event emitted
    function test_lazyMint_event() public {
        vm.startPrank(deployer_signer);

        bytes memory data = abi.encode("", 0);

        vm.expectEmit(true, true, false, false);
        emit TokenLazyMinted(0, 100, "ipfs://", "sdc");
        sigdrop.lazyMint(100, "ipfs://", data);
        
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                Delayed Reveal Tests
    //////////////////////////////////////////////////////////////*/

    // - test access/roles
    function test_delayedReveal_minterRole() public {
        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        vm.prank(deployer_signer);
        sigdrop.lazyMint(100, "", data);

        vm.prank(deployer_signer);
        sigdrop.reveal(0, "key");

        bytes memory errorMessage =
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(address(this)), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(keccak256("MINTER_ROLE")), 32)
                    );

        vm.expectRevert(errorMessage);
        sigdrop.reveal(0, "key");
    }

    // - test _index valid/invalid, getBatchIdAtIndex
    function test_delayedReveal_getBatchIdAtIndex() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);
        sigdrop.reveal(0, "key");

        data = abi.encode(encryptedURI, 100);
        sigdrop.lazyMint(100, "", data);
        vm.expectRevert("invalid index.");
        sigdrop.reveal(2, "key");

        vm.stopPrank();
    }

    // - test getRevealURI
    function test_delayedReveal_getRevealURI() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);

        string memory revealedURI = sigdrop.reveal(0, "key");
        assertEq(revealedURI, "ipfs://");
        /// note: probably need to check encryptDecrypt in more detail, and not just "keyy"

        vm.stopPrank();
    }

    // - test incorrect key
    function testFail_delayedReveal_incorrectKey() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);

        string memory revealedURI = sigdrop.reveal(0, "keyy");
        assertEq(revealedURI, "ipfs://");
        /// note: probably need to check encryptDecrypt in more detail, and not just "keyy"

        vm.stopPrank();
    }
    
    // - test _setBaseURI
    function test_delayedReveal_setBaseURI() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);
        sigdrop.reveal(0, "key");

        string memory uri = sigdrop.tokenURI(1);
        assertEq(uri, "ipfs://1");

        vm.stopPrank();
    }

    // - test event emitted
    function test_delayedReveal_event() public {
        vm.startPrank(deployer_signer);

        bytes memory encryptedURI = sigdrop.encryptDecrypt("ipfs://", "key");
        bytes memory data = abi.encode(encryptedURI, 0);
        sigdrop.lazyMint(100, "", data);

        vm.expectEmit(false, false, false, true);
        emit TokenURIRevealed(0, "ipfs://");
        sigdrop.reveal(0, "key");
        
        vm.stopPrank();
    }

    /*///////////////////////////////////////////////////////////////
                                Signature Mint Tests
    //////////////////////////////////////////////////////////////*/

    // - test _processRequest and recover signer
    function test_mintWithSignature_processRequestAndRecoverSigner() public {
        bytes memory data = abi.encode("", 0);
        vm.prank(deployer_signer);
        sigdrop.lazyMint(100, "ipfs://", data);
        uint256 id = 0;

        SignatureDrop.MintRequest memory mintrequest;
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
                typehash,
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
        bytes memory signature = abi.encodePacked(r,s,v);
        vm.warp(1000);
        sigdrop.mintWithSignature(mintrequest, signature);

        (v, r, s) = vm.sign(4321, typedDataHash);
        signature = abi.encodePacked(r,s,v);
        vm.expectRevert("Invalid request");
        sigdrop.mintWithSignature(mintrequest, signature);
    }

    // - test price and currencies
    function test_mintWithSignature_priceAndCurrency() public {
        bytes memory data = abi.encode("", 0);
        vm.prank(deployer_signer);
        sigdrop.lazyMint(100, "ipfs://", data);
        uint256 id = 0;
        SignatureDrop.MintRequest memory mintrequest;

        {
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

            bytes memory encodedRequest = abi.encode(
                    typehash,
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
            bytes memory signature = abi.encodePacked(r,s,v);
            vm.startPrank(deployer_signer);          
            vm.warp(1000);
            erc20.approve(address(sigdrop), 1);
            sigdrop.mintWithSignature(mintrequest, signature);
            vm.stopPrank();
        }

        // {
        //     mintrequest.currency = address(NATIVE_TOKEN);
        //     bytes memory encodedRequest = abi.encode(
        //             typehash,
        //             mintrequest.to,
        //             mintrequest.royaltyRecipient,
        //             mintrequest.royaltyBps,
        //             mintrequest.primarySaleRecipient,
        //             keccak256(bytes(mintrequest.uri)),
        //             mintrequest.quantity,
        //             mintrequest.pricePerToken,
        //             mintrequest.currency,
        //             mintrequest.validityStartTimestamp,
        //             mintrequest.validityEndTimestamp,
        //             mintrequest.uid
        //         );
        //     bytes32 structHash = keccak256(encodedRequest);
        //     bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        //     vm.startPrank(deployer_signer);
        //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        //     bytes memory signature = abi.encodePacked(r,s,v);
        //     sigdrop.mintWithSignature(mintrequest, signature);
        //     vm.stopPrank();
        // }
    }



    /*///////////////////////////////////////////////////////////////
                                Claim Tests
    //////////////////////////////////////////////////////////////*/

    // claim tests
    function test_claimCondition_startIdAndCount() public {
        vm.startPrank(deployer_signer);

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

    function test_claimCondition_startPhase() public {
        vm.startPrank(deployer_signer);

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

    function test_claimCondition_waitTimeInSecondsBetweenClaims() public {
        vm.warp(1);

        address receiver = getActor(0);
        bytes32[] memory proofs = new bytes32[](0);

        SignatureDrop.AllowlistProof memory alp;
        alp.proof = proofs;

        SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        // vm.prank(deployer);
        // sigdrop.lazyMint(100, "ipfs://", bytes(""));
        // vm.prank(deployer);
        // sigdrop.setClaimConditions(conditions, false, "");

        // vm.prank(getActor(5), getActor(5));
        // sigdrop.claim(receiver, 1, address(0), 0, alp, "");

        // vm.expectRevert("cannot claim.");
        // vm.prank(getActor(5), getActor(5));
        // sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    }

    // function test_claimCondition_resetEligibility_waitTimeInSecondsBetweenClaims() public {
    //     vm.warp(1);

    //     address receiver = getActor(0);
    //     bytes32[] memory proofs = new bytes32[](0);

    //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 100;
    //     conditions[0].quantityLimitPerTransaction = 100;
    //     conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

    //     vm.prank(deployer);
    //     sigdrop.lazyMint(100, "ipfs://", bytes(""));

    //     vm.prank(deployer);
    //     sigdrop.setClaimConditions(conditions, false);

    //     vm.prank(getActor(5), getActor(5));
    //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);

    //     vm.prank(deployer);
    //     sigdrop.setClaimConditions(conditions, true);

    //     vm.prank(getActor(5), getActor(5));
    //     sigdrop.claim(receiver, 1, address(0), 0, proofs, 0);
    // }

    // function test_multiple_claim_exploit() public {
    //     MasterExploitContract masterExploit = new MasterExploitContract(address(sigdrop));

    //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 100;
    //     conditions[0].quantityLimitPerTransaction = 1;
    //     conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

    //     vm.prank(deployer);
    //     sigdrop.lazyMint(100, "ipfs://", bytes(""));

    //     vm.prank(deployer);
    //     sigdrop.setClaimConditions(conditions, false);

    //     bytes32[] memory proofs = new bytes32[](0);

    //     vm.startPrank(getActor(5));
    //     vm.expectRevert(bytes("BOT"));
    //     masterExploit.performExploit(
    //         address(masterExploit),
    //         conditions[0].quantityLimitPerTransaction,
    //         conditions[0].currency,
    //         conditions[0].pricePerToken,
    //         proofs,
    //         0
    //     );
    // }
}