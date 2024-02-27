// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./utils/BaseTest.sol";
import "contracts/infra/TWProxy.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { LoyaltyCard, NFTMetadata } from "contracts/prebuilts/loyalty/LoyaltyCard.sol";

contract LoyaltyCardTest is BaseTest {
    LoyaltyCard internal loyaltyCard;
    using Strings for uint256;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    LoyaltyCard.MintRequest _mintrequest;
    bytes _signature;

    address recipient;

    function setUp() public override {
        super.setUp();

        address loyaltyCardImpl = address(new LoyaltyCard());

        vm.prank(signer);
        loyaltyCard = LoyaltyCard(
            address(
                new TWProxy(
                    loyaltyCardImpl,
                    abi.encodeCall(
                        LoyaltyCard.initialize,
                        (
                            signer,
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

        recipient = address(0x123);
        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(loyaltyCard))
        );

        _mintrequest.to = recipient;
        _mintrequest.royaltyRecipient = royaltyRecipient;
        _mintrequest.royaltyBps = royaltyBps;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 1;
        _mintrequest.pricePerToken = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        LoyaltyCard.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            keccak256(bytes(_request.uri)),
            _request.quantity,
            _request.pricePerToken,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintTo() public {
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = loyaltyCard.nextTokenIdToMint();
        uint256 currentTotalSupply = loyaltyCard.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyCard.balanceOf(recipient);

        vm.prank(signer);
        loyaltyCard.mintTo(recipient, _tokenURI);

        assertEq(loyaltyCard.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(loyaltyCard.tokenURI(nextTokenId), _tokenURI);
        assertEq(loyaltyCard.totalSupply(), currentTotalSupply + 1);
        assertEq(loyaltyCard.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(loyaltyCard.ownerOf(nextTokenId), recipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `setTokenURI`
    //////////////////////////////////////////////////////////////*/

    function test_state_setTokenURI() public {
        string memory _tokenURI = "tokenURI";

        vm.prank(signer);
        uint256 tokenIdMinted = loyaltyCard.mintTo(recipient, _tokenURI);

        assertEq(_tokenURI, loyaltyCard.tokenURI(tokenIdMinted));

        assertEq(loyaltyCard.hasRole(keccak256("METADATA_ROLE"), signer), true);

        string memory newURI = "newURI";

        vm.prank(signer);
        loyaltyCard.setTokenURI(tokenIdMinted, newURI);

        assertEq(newURI, loyaltyCard.tokenURI(tokenIdMinted));

        vm.prank(signer);
        loyaltyCard.renounceRole(keccak256("METADATA_ROLE"), signer);

        vm.expectRevert();
        vm.prank(signer);
        loyaltyCard.setTokenURI(tokenIdMinted, _tokenURI);

        vm.expectRevert();
        vm.prank(signer);
        loyaltyCard.grantRole(keccak256("METADATA_ROLE"), signer);
    }

    /*///////////////////////////////////////////////////////////////
                    Unit tests: cancel / revoke loyalty
    //////////////////////////////////////////////////////////////*/

    function test_state_cancelLoyalty() public {
        string memory _tokenURI = "tokenURI";

        vm.prank(signer);
        uint256 tokenIdMinted = loyaltyCard.mintTo(recipient, _tokenURI);

        assertEq(loyaltyCard.ownerOf(tokenIdMinted), recipient);

        vm.prank(recipient);
        loyaltyCard.setApprovalForAll(signer, true);

        vm.prank(signer);
        loyaltyCard.cancel(tokenIdMinted);

        vm.expectRevert();
        loyaltyCard.ownerOf(tokenIdMinted);
    }

    function test_state_revokeLoyalty() public {
        string memory _tokenURI = "tokenURI";

        vm.prank(signer);
        uint256 tokenIdMinted = loyaltyCard.mintTo(recipient, _tokenURI);

        assertEq(loyaltyCard.ownerOf(tokenIdMinted), recipient);

        address burner = address(0x123456);
        vm.prank(signer);
        loyaltyCard.grantRole(keccak256("REVOKE_ROLE"), burner);

        vm.prank(signer);
        loyaltyCard.renounceRole(keccak256("REVOKE_ROLE"), signer);

        vm.expectRevert();
        vm.prank(signer);
        loyaltyCard.revoke(tokenIdMinted);

        vm.prank(burner);
        loyaltyCard.revoke(tokenIdMinted);

        vm.expectRevert();
        loyaltyCard.ownerOf(tokenIdMinted);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        uint256 nextTokenId = loyaltyCard.nextTokenIdToMint();
        uint256 currentTotalSupply = loyaltyCard.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyCard.balanceOf(recipient);

        loyaltyCard.mintWithSignature(_mintrequest, _signature);

        assertEq(loyaltyCard.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(loyaltyCard.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(loyaltyCard.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyCard.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(loyaltyCard.ownerOf(nextTokenId), recipient);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(loyaltyCard), 1);

        uint256 nextTokenId = loyaltyCard.nextTokenIdToMint();
        uint256 currentTotalSupply = loyaltyCard.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyCard.balanceOf(recipient);

        vm.prank(recipient);
        loyaltyCard.mintWithSignature(_mintrequest, _signature);

        assertEq(loyaltyCard.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(loyaltyCard.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(loyaltyCard.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyCard.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(loyaltyCard.ownerOf(nextTokenId), recipient);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        uint256 nextTokenId = loyaltyCard.nextTokenIdToMint();
        uint256 currentTotalSupply = loyaltyCard.totalSupply();
        uint256 currentBalanceOfRecipient = loyaltyCard.balanceOf(recipient);

        vm.deal(recipient, 1);

        vm.prank(recipient);
        loyaltyCard.mintWithSignature{ value: 1 }(_mintrequest, _signature);

        assertEq(loyaltyCard.nextTokenIdToMint(), nextTokenId + _mintrequest.quantity);
        assertEq(loyaltyCard.tokenURI(nextTokenId), string(abi.encodePacked(_mintrequest.uri)));
        assertEq(loyaltyCard.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(loyaltyCard.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(loyaltyCard.ownerOf(nextTokenId), recipient);
    }

    function test_revert_mintWithSignature_InvalidMsgValue() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("Invalid msg value");
        loyaltyCard.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_ZeroQty() public {
        vm.warp(1000);

        _mintrequest.quantity = 0;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("LoyaltyCard: only 1 NFT can be minted at a time.");
        loyaltyCard.mintWithSignature(_mintrequest, _signature);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `setTokenURI`
    //////////////////////////////////////////////////////////////*/

    function test_setTokenURI_state() public {
        string memory uri = "uri_string";

        vm.prank(signer);
        loyaltyCard.setTokenURI(0, uri);

        string memory _tokenURI = loyaltyCard.tokenURI(0);

        assertEq(_tokenURI, uri);
    }

    function test_setTokenURI_revert_NotAuthorized() public {
        string memory uri = "uri_string";

        vm.expectRevert(abi.encodeWithSelector(NFTMetadata.NFTMetadataUnauthorized.selector));
        vm.prank(address(0x1));
        loyaltyCard.setTokenURI(0, uri);
    }

    function test_setTokenURI_revert_Frozen() public {
        string memory uri = "uri_string";

        vm.startPrank(signer);
        loyaltyCard.freezeMetadata();

        vm.expectRevert(abi.encodeWithSelector(NFTMetadata.NFTMetadataFrozen.selector, 0));
        loyaltyCard.setTokenURI(0, uri);
    }

    /*///////////////////////////////////////////////////////////////
                        Audit fixes tests
    //////////////////////////////////////////////////////////////*/

    function test_audit_quantity_not_1() public {
        vm.warp(1000);
        _mintrequest.pricePerToken = 1;
        _mintrequest.quantity = 5;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(loyaltyCard), 5);

        vm.prank(recipient);
        vm.expectRevert("LoyaltyCard: only 1 NFT can be minted at a time.");
        loyaltyCard.mintWithSignature(_mintrequest, _signature);
    }
}
