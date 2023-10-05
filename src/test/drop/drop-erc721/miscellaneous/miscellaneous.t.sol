// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, IDelayedReveal, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC721Test_misc is BaseTest {
    using StringsUpgradeable for uint256;

    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    DropERC721 public drop;

    bytes private reveal_data;
    string private reveal_baseURI;
    uint256 private reveal_amount;
    bytes private reveal_encryptedURI;
    bytes32 private reveal_provenanceHash;
    string private reveal_revealedURI;
    uint256 private reveal_index;
    bytes private reveal_key;
    address private unauthorized = address(0x123);

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerWithoutMetadataRole() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerWithMetadataRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier callerNotApproved() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerOwner() {
        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        vm.startPrank(receiver);
        _;
    }

    modifier callerApproved() {
        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3);
        vm.prank(receiver);
        drop.setApprovalForAll(deployer, true);
        vm.startPrank(deployer);
        _;
    }

    modifier validIndex() {
        reveal_index = 0;
        _;
    }

    modifier invalidKey() {
        reveal_key = "invalidKey";
        _;
    }

    modifier invalidIndex() {
        reveal_index = 1;
        _;
    }

    modifier lazyMintEncrypted() {
        reveal_amount = 10;
        reveal_baseURI = "ipfs://";
        reveal_revealedURI = "ipfs://revealed";
        reveal_key = "key";
        reveal_encryptedURI = drop.encryptDecrypt(bytes(reveal_revealedURI), reveal_key);
        reveal_provenanceHash = keccak256(abi.encodePacked(reveal_revealedURI, reveal_key, block.chainid));
        reveal_data = abi.encode(reveal_encryptedURI, reveal_provenanceHash);
        vm.prank(deployer);
        drop.lazyMint(reveal_amount, reveal_baseURI, reveal_data);
        _;
    }

    modifier lazyMintUnEncrypted() {
        reveal_amount = 10;
        reveal_baseURI = "ipfs://";
        vm.prank(deployer);
        drop.lazyMint(reveal_amount, reveal_baseURI, reveal_data);
        _;
    }

    modifier tokenClaimed() {
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

        DropERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0x92Bb439374a091c7507bE100183d8D1Ed2c9dAD3); // in allowlist

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 10, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        _;
    }

    function test_totalMinted_TenLazyMintedZeroClaim() public lazyMintEncrypted {
        uint256 totalMinted = drop.totalMinted();
        assertEq(totalMinted, 0);
    }

    function test_totalMinted_TenLazyMintedTenClaim() public lazyMintEncrypted tokenClaimed {
        uint256 totalMinted = drop.totalMinted();
        assertEq(totalMinted, 10);
    }

    function test_nextTokenIdToMint_ZeroLazyMinted() public {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 0);
    }

    function test_nextTokenIdToMint_TenLazyMinted() public lazyMintEncrypted {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 10);
    }

    function test_nextTokenIdToClaim_ZeroClaimed() public {
        uint256 nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(nextTokenIdToClaim, 0);
    }

    function test_nextTokenIdToClaim_TenClaimed() public lazyMintEncrypted tokenClaimed {
        uint256 nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(nextTokenIdToClaim, 10);
    }

    function test_burn_revert_callerNotApproved() public lazyMintEncrypted tokenClaimed callerNotApproved {
        vm.expectRevert(IERC721AUpgradeable.TransferCallerNotOwnerNorApproved.selector);
        drop.burn(0);
    }

    function test_burn_CallerApproved() public lazyMintEncrypted tokenClaimed callerApproved {
        drop.burn(0);
        uint256 totalSupply = drop.totalSupply();
        assertEq(totalSupply, 9);
        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        drop.ownerOf(0);
    }

    function test_burn_revert_callerOwnerOfToken() public lazyMintEncrypted tokenClaimed callerOwner {
        drop.burn(0);
        uint256 totalSupply = drop.totalSupply();
        assertEq(totalSupply, 9);
        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        drop.ownerOf(0);
    }
}
