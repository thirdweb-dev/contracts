// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SignatureDrop, IDropSinglePhase, IDelayedReveal, ISignatureMintERC721, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/signature-drop/SignatureDrop.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "../utils/BaseTest.sol";

contract SignatureDropBenchmarkTest is BaseTest {
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
                        SignatureDrop benchmark
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_signatureDrop_claim_five_tokens() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();
        sigdrop.claim(receiver, 5, address(0), 0, alp, "");
    }

    function test_benchmark_signatureDrop_setClaimConditions() public {
        vm.pauseGasMetering();
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
        vm.resumeGasMetering();
        sigdrop.setClaimConditions(conditions[0], false);
    }

    function test_benchmark_signatureDrop_lazyMint() public {
        vm.pauseGasMetering();
        vm.prank(deployerSigner);
        vm.resumeGasMetering();
        sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);
    }

    function test_benchmark_signatureDrop_lazyMint_for_delayed_reveal() public {
        vm.pauseGasMetering();
        uint256 amountToLazyMint = 100;
        string memory baseURI = "ipfs://";
        bytes memory encryptedBaseURI = "encryptedBaseURI://";
        bytes32 provenanceHash = bytes32("whatever");

        vm.prank(deployerSigner);
        vm.resumeGasMetering();
        sigdrop.lazyMint(amountToLazyMint, baseURI, abi.encode(encryptedBaseURI, provenanceHash));
    }

    function test_benchmark_signatureDrop_reveal() public {
        vm.pauseGasMetering();

        bytes memory key = "key";
        uint256 amountToLazyMint = 100;
        bytes memory secretURI = "ipfs://";
        string memory placeholderURI = "abcd://";
        bytes memory encryptedURI = sigdrop.encryptDecrypt(secretURI, key);
        bytes32 provenanceHash = keccak256(abi.encodePacked(secretURI, key, block.chainid));

        vm.prank(deployerSigner);
        sigdrop.lazyMint(amountToLazyMint, placeholderURI, abi.encode(encryptedURI, provenanceHash));

        vm.prank(deployerSigner);
        vm.resumeGasMetering();
        sigdrop.reveal(0, key);
    }

    // function test_benchmark_signatureDrop_claim_one_token() public {
    //     vm.pauseGasMetering();
    //     vm.warp(1);

    //     address receiver = getActor(0);
    //     bytes32[] memory proofs = new bytes32[](0);

    //     SignatureDrop.AllowlistProof memory alp;
    //     alp.proof = proofs;

    //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 100;
    //     conditions[0].quantityLimitPerWallet = 100;

    //     vm.prank(deployerSigner);
    //     sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

    //     vm.prank(deployerSigner);
    //     sigdrop.setClaimConditions(conditions[0], false);

    //     vm.prank(getActor(5), getActor(5));
    //     vm.resumeGasMetering();
    //     sigdrop.claim(receiver, 1, address(0), 0, alp, "");
    // }

    // function test_benchmark_signatureDrop_claim_two_tokens() public {
    //     vm.pauseGasMetering();
    //     vm.warp(1);

    //     address receiver = getActor(0);
    //     bytes32[] memory proofs = new bytes32[](0);

    //     SignatureDrop.AllowlistProof memory alp;
    //     alp.proof = proofs;

    //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 100;
    //     conditions[0].quantityLimitPerWallet = 100;

    //     vm.prank(deployerSigner);
    //     sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

    //     vm.prank(deployerSigner);
    //     sigdrop.setClaimConditions(conditions[0], false);

    //     vm.prank(getActor(5), getActor(5));
    //     vm.resumeGasMetering();
    //     sigdrop.claim(receiver, 2, address(0), 0, alp, "");
    // }

    // function test_benchmark_signatureDrop_claim_three_tokens() public {
    //     vm.pauseGasMetering();
    //     vm.warp(1);

    //     address receiver = getActor(0);
    //     bytes32[] memory proofs = new bytes32[](0);

    //     SignatureDrop.AllowlistProof memory alp;
    //     alp.proof = proofs;

    //     SignatureDrop.ClaimCondition[] memory conditions = new SignatureDrop.ClaimCondition[](1);
    //     conditions[0].maxClaimableSupply = 100;
    //     conditions[0].quantityLimitPerWallet = 100;

    //     vm.prank(deployerSigner);
    //     sigdrop.lazyMint(100, "ipfs://", emptyEncodedBytes);

    //     vm.prank(deployerSigner);
    //     sigdrop.setClaimConditions(conditions[0], false);

    //     vm.prank(getActor(5), getActor(5));
    //     vm.resumeGasMetering();
    //     sigdrop.claim(receiver, 3, address(0), 0, alp, "");
    // }
}
