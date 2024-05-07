// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { ERC1155SignatureMint } from "contracts/base/ERC1155SignatureMint.sol";
import { Strings } from "contracts/lib/Strings.sol";

contract ERC1155SignatureMintTest is DSTest, Test {
    using Strings for uint256;

    // Target contract
    ERC1155SignatureMint internal base;

    // Signers
    uint256 internal adminPkey;
    uint256 internal nftHolderPkey;

    address internal admin;
    address internal nftHolder;
    address internal saleRecipient;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    ERC1155SignatureMint.MintRequest req;

    function signMintRequest(
        ERC1155SignatureMint.MintRequest memory _request,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = bytes.concat(
            abi.encode(
                typehashMintRequest,
                _request.to,
                _request.royaltyRecipient,
                _request.royaltyBps,
                _request.primarySaleRecipient,
                _request.tokenId,
                keccak256(bytes(_request.uri))
            ),
            abi.encode(
                _request.quantity,
                _request.pricePerToken,
                _request.currency,
                _request.validityStartTimestamp,
                _request.validityEndTimestamp,
                _request.uid
            )
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function setUp() public {
        adminPkey = 123;
        nftHolderPkey = 456;

        admin = vm.addr(adminPkey);
        nftHolder = vm.addr(nftHolderPkey);
        saleRecipient = address(0x8910);

        vm.deal(nftHolder, 100 ether);

        vm.prank(admin);
        base = new ERC1155SignatureMint(admin, "name", "symbol", admin, 0, saleRecipient);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC1155"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(base)));
    }

    function test_state_mintWithSignature_newNFTs() public {
        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = type(uint256).max;
        req.uri = "ipfs://";
        req.quantity = 100;
        req.pricePerToken = 0;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        bytes memory signature = signMintRequest(req, adminPkey);

        uint256 tokenId = base.nextTokenIdToMint();
        assertEq(base.totalSupply(tokenId), 0);

        vm.prank(nftHolder);
        base.mintWithSignature(req, signature);

        assertEq(base.balanceOf(nftHolder, tokenId), req.quantity);
        assertEq(base.totalSupply(tokenId), req.quantity);
        assertEq(base.uri(tokenId), req.uri);
    }

    function test_state_mintWithSignature_existingNFTs() public {
        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = type(uint256).max;
        req.uri = "ipfs://";
        req.quantity = 100;
        req.pricePerToken = 0;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        bytes memory signature = signMintRequest(req, adminPkey);

        uint256 tokenId = base.nextTokenIdToMint();
        assertEq(base.totalSupply(tokenId), 0);

        vm.prank(nftHolder);
        base.mintWithSignature(req, signature);

        assertEq(base.balanceOf(nftHolder, tokenId), req.quantity);
        assertEq(base.totalSupply(tokenId), req.quantity);

        req.tokenId = tokenId;
        string memory originalURI = req.uri;
        req.uri = "wrongURI://";
        req.uid = keccak256("new uid");

        bytes memory signature2 = signMintRequest(req, adminPkey);
        vm.prank(nftHolder);
        base.mintWithSignature(req, signature2);

        assertEq(base.balanceOf(nftHolder, tokenId), req.quantity * 2);
        assertEq(base.totalSupply(tokenId), req.quantity * 2);
        assertEq(base.uri(tokenId), originalURI);
    }

    function test_state_mintWithSignature_withPrice() public {
        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = type(uint256).max;
        req.uri = "ipfs://";
        req.quantity = 100;
        req.pricePerToken = 0.01 ether;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        uint256 saleRecipientBalBefore = saleRecipient.balance;
        uint256 totalPrice = req.pricePerToken * req.quantity;

        bytes memory signature = signMintRequest(req, adminPkey);
        vm.prank(nftHolder);
        base.mintWithSignature{ value: totalPrice }(req, signature);

        assertEq(saleRecipient.balance, saleRecipientBalBefore + totalPrice);
    }

    function test_revert_mintWithSignature_withPrice_incorrectPrice() public {
        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = type(uint256).max;
        req.uri = "ipfs://";
        req.quantity = 100;
        req.pricePerToken = 0.01 ether;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        uint256 totalPrice = req.pricePerToken * req.quantity;
        bytes memory signature = signMintRequest(req, adminPkey);
        vm.prank(nftHolder);
        vm.expectRevert("Invalid msg value");
        base.mintWithSignature{ value: totalPrice - 1 }(req, signature);
    }

    function test_revert_mintWithSignature_mintingZeroTokens() public {
        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = type(uint256).max;
        req.uri = "ipfs://";
        req.quantity = 0;
        req.pricePerToken = 0;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        bytes memory signature = signMintRequest(req, adminPkey);
        vm.prank(nftHolder);
        vm.expectRevert("Minting zero tokens.");
        base.mintWithSignature(req, signature);
    }

    function test_revert_mintWithSignature_invalidId() public {
        uint256 nextId = base.nextTokenIdToMint();

        req.to = nftHolder;
        req.royaltyRecipient = admin;
        req.royaltyBps = 0;
        req.primarySaleRecipient = saleRecipient;
        req.tokenId = nextId;
        req.uri = "ipfs://";
        req.quantity = 100;
        req.pricePerToken = 0;
        req.currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        req.validityStartTimestamp = 0;
        req.validityEndTimestamp = type(uint128).max;
        req.uid = keccak256("uid");

        bytes memory signature = signMintRequest(req, adminPkey);
        vm.prank(nftHolder);
        vm.expectRevert("invalid id");
        base.mintWithSignature(req, signature);
    }
}
