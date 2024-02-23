// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenERC721, NFTMetadata } from "contracts/prebuilts/token/TokenERC721.sol";

// Test imports

import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TokenERC721Test is BaseTest {
    using Strings for uint256;

    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC721.MintRequest mintRequest
    );
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
    event PrimarySaleRecipientUpdated(address indexed recipient);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    TokenERC721 public tokenContract;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    bytes private emptyEncodedBytes = abi.encode("", "");

    TokenERC721.MintRequest _mintrequest;
    bytes _signature;

    address internal deployerSigner;
    address internal recipient;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        recipient = address(0x123);
        tokenContract = TokenERC721(getContract("TokenERC721"));

        erc20.mint(deployerSigner, 1_000);
        vm.deal(deployerSigner, 1_000);

        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("TokenERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tokenContract))
        );

        // construct default mintrequest
        _mintrequest.to = recipient;
        _mintrequest.royaltyRecipient = royaltyRecipient;
        _mintrequest.royaltyBps = royaltyBps;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.uri = "ipfs://";
        _mintrequest.price = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        TokenERC721.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            keccak256(bytes(_request.uri)),
            _request.price,
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
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        // initial balances and state
        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        // mint with signature
        vm.prank(recipient);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after minting
        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), string(_mintrequest.uri));
        assertEq(tokenContract.totalSupply(), currentTotalSupply + 1);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(tokenContract.ownerOf(nextTokenId), recipient);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.price = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        // approve erc20 tokens to tokenContract
        vm.prank(recipient);
        erc20.approve(address(tokenContract), 1);

        // initial balances and state
        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        uint256 erc20BalanceOfSeller = erc20.balanceOf(address(saleRecipient));
        uint256 erc20BalanceOfRecipient = erc20.balanceOf(address(recipient));

        // mint with signature
        vm.prank(recipient);
        tokenContract.mintWithSignature(_mintrequest, _signature);

        // check state after minting
        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), string(_mintrequest.uri));
        assertEq(tokenContract.totalSupply(), currentTotalSupply + 1);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(tokenContract.ownerOf(nextTokenId), recipient);

        // check erc20 balances after minting
        uint256 _platformFees = (_mintrequest.price * platformFeeBps) / MAX_BPS;
        assertEq(erc20.balanceOf(recipient), erc20BalanceOfRecipient - _mintrequest.price);
        assertEq(erc20.balanceOf(address(saleRecipient)), erc20BalanceOfSeller + _mintrequest.price - _platformFees);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        // initial balances and state
        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        uint256 etherBalanceOfSeller = address(saleRecipient).balance;
        uint256 etherBalanceOfRecipient = address(recipient).balance;

        // mint with signature
        vm.prank(recipient);
        tokenContract.mintWithSignature{ value: 1 }(_mintrequest, _signature);

        // check state after minting
        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), string(_mintrequest.uri));
        assertEq(tokenContract.totalSupply(), currentTotalSupply + 1);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(tokenContract.ownerOf(nextTokenId), recipient);

        // check erc20 balances after minting
        uint256 _platformFees = (_mintrequest.price * platformFeeBps) / MAX_BPS;
        assertEq(address(recipient).balance, etherBalanceOfRecipient - _mintrequest.price);
        assertEq(address(saleRecipient).balance, etherBalanceOfSeller + _mintrequest.price - _platformFees);
    }

    function test_revert_mintWithSignature_MustSendTotalPrice() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("must send total price.");
        tokenContract.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_MsgValueNotZero() public {
        vm.warp(1000);

        _mintrequest.price = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        // shouldn't send native-token when it is not the currency
        vm.prank(recipient);
        vm.expectRevert("msg value not zero");
        tokenContract.mintWithSignature{ value: 1 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_InvalidSignature() public {
        vm.warp(1000);

        uint256 incorrectKey = 3456;
        _signature = signMintRequest(_mintrequest, incorrectKey);

        vm.prank(recipient);
        vm.expectRevert("invalid signature");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_RequestExpired() public {
        _signature = signMintRequest(_mintrequest, privateKey);

        // warp time more out of range
        vm.warp(3000);

        vm.prank(recipient);
        vm.expectRevert("request expired");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_RecipientUndefined() public {
        vm.warp(1000);

        _mintrequest.to = address(0);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("recipient undefined");
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_event_mintWithSignature() public {
        vm.warp(1000);

        vm.expectEmit(true, true, true, true);
        emit TokensMintedWithSignature(deployerSigner, recipient, 0, _mintrequest);

        // mint with signature
        vm.prank(recipient);
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintTo`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintTo() public {
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, _tokenURI);

        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), _tokenURI);
        assertEq(tokenContract.totalSupply(), currentTotalSupply + 1);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient + 1);
        assertEq(tokenContract.ownerOf(nextTokenId), recipient);
    }

    function test_revert_mintTo_NotAuthorized() public {
        string memory _tokenURI = "tokenURI";
        bytes32 role = keccak256("MINTER_ROLE");

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.mintTo(recipient, _tokenURI);
    }

    function test_revert_mintTo_emptyURI() public {
        // mint
        vm.prank(deployerSigner);
        vm.expectRevert("empty uri.");
        tokenContract.mintTo(recipient, "");
    }

    function test_event_mintTo() public {
        string memory _tokenURI = "tokenURI";

        vm.expectEmit(true, true, true, true);
        emit TokensMinted(recipient, 0, _tokenURI);

        // mint
        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, _tokenURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `burn`
    //////////////////////////////////////////////////////////////*/

    function test_state_burn_TokenOwner() public {
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, _tokenURI);

        vm.prank(recipient);
        tokenContract.burn(nextTokenId);

        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), _tokenURI);
        assertEq(tokenContract.totalSupply(), currentTotalSupply);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient);

        vm.expectRevert("ERC721: invalid token ID");
        assertEq(tokenContract.ownerOf(nextTokenId), address(0));
    }

    function test_state_burn_TokenOperator() public {
        string memory _tokenURI = "tokenURI";

        address operator = address(0x789);

        uint256 nextTokenId = tokenContract.nextTokenIdToMint();
        uint256 currentTotalSupply = tokenContract.totalSupply();
        uint256 currentBalanceOfRecipient = tokenContract.balanceOf(recipient);

        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, _tokenURI);

        vm.prank(recipient);
        tokenContract.setApprovalForAll(operator, true);

        vm.prank(operator);
        tokenContract.burn(nextTokenId);

        assertEq(tokenContract.nextTokenIdToMint(), nextTokenId + 1);
        assertEq(tokenContract.tokenURI(nextTokenId), _tokenURI);
        assertEq(tokenContract.totalSupply(), currentTotalSupply);
        assertEq(tokenContract.balanceOf(recipient), currentBalanceOfRecipient);

        vm.expectRevert("ERC721: invalid token ID");
        assertEq(tokenContract.ownerOf(nextTokenId), address(0));
    }

    function test_revert_burn_NotOwnerNorApproved() public {
        string memory _tokenURI = "tokenURI";

        uint256 nextTokenId = tokenContract.nextTokenIdToMint();

        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, _tokenURI);

        vm.prank(address(0x789));
        vm.expectRevert("ERC721Burnable: caller is not owner nor approved");
        tokenContract.burn(nextTokenId);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: owner
    //////////////////////////////////////////////////////////////*/

    function test_state_setOwner() public {
        address newOwner = address(0x123);
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.prank(deployerSigner);
        tokenContract.grantRole(role, newOwner);

        vm.prank(deployerSigner);
        tokenContract.setOwner(newOwner);

        assertEq(tokenContract.owner(), newOwner);
    }

    function test_revert_setOwner_NotModuleAdmin() public {
        vm.expectRevert("new owner not module admin.");
        vm.prank(deployerSigner);
        tokenContract.setOwner(address(0x1234));
    }

    function test_event_setOwner() public {
        address newOwner = address(0x123);
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.startPrank(deployerSigner);
        tokenContract.grantRole(role, newOwner);

        vm.expectEmit(true, true, true, true);
        emit OwnerUpdated(deployerSigner, newOwner);

        tokenContract.setOwner(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: royalty
    //////////////////////////////////////////////////////////////*/

    function test_state_setDefaultRoyaltyInfo() public {
        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 1000;

        vm.prank(deployerSigner);
        tokenContract.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        (address newRoyaltyRecipient, uint256 newRoyaltyBps) = tokenContract.getDefaultRoyaltyInfo();
        assertEq(newRoyaltyRecipient, _royaltyRecipient);
        assertEq(newRoyaltyBps, _royaltyBps);

        (address receiver, uint256 royaltyAmount) = tokenContract.royaltyInfo(0, 100);
        assertEq(receiver, _royaltyRecipient);
        assertEq(royaltyAmount, (100 * 1000) / 10_000);
    }

    function test_revert_setDefaultRoyaltyInfo_NotAuthorized() public {
        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 1000;
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function test_revert_setDefaultRoyaltyInfo_ExceedsRoyaltyBps() public {
        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 10001;

        vm.expectRevert("exceed royalty bps");
        vm.prank(deployerSigner);
        tokenContract.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function test_state_setRoyaltyInfoForToken() public {
        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 1000;

        vm.prank(deployerSigner);
        tokenContract.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);

        (address receiver, uint256 royaltyAmount) = tokenContract.royaltyInfo(_tokenId, 100);
        assertEq(receiver, _recipient);
        assertEq(royaltyAmount, (100 * 1000) / 10_000);
    }

    function test_revert_setRoyaltyInfo_NotAuthorized() public {
        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 1000;
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    function test_revert_setRoyaltyInfoForToken_ExceedsRoyaltyBps() public {
        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 10001;

        vm.expectRevert("exceed royalty bps");
        vm.prank(deployerSigner);
        tokenContract.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    function test_event_defaultRoyalty() public {
        address _royaltyRecipient = address(0x123);
        uint256 _royaltyBps = 1000;

        vm.expectEmit(true, true, true, true);
        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);

        vm.prank(deployerSigner);
        tokenContract.setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function test_event_royaltyForToken() public {
        uint256 _tokenId = 1;
        address _recipient = address(0x123);
        uint256 _bps = 1000;

        vm.expectEmit(true, true, true, true);
        emit RoyaltyForToken(_tokenId, _recipient, _bps);

        vm.prank(deployerSigner);
        tokenContract.setRoyaltyInfoForToken(_tokenId, _recipient, _bps);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: primary sale
    //////////////////////////////////////////////////////////////*/

    function test_state_setPrimarySaleRecipient() public {
        address _primarySaleRecipient = address(0x123);

        vm.prank(deployerSigner);
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);

        address recipient_ = tokenContract.primarySaleRecipient();
        assertEq(recipient_, _primarySaleRecipient);
    }

    function test_revert_setPrimarySaleRecipient_NotAuthorized() public {
        address _primarySaleRecipient = address(0x123);
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);
    }

    function test_event_setPrimarySaleRecipient() public {
        address _primarySaleRecipient = address(0x123);

        vm.expectEmit(true, true, true, true);
        emit PrimarySaleRecipientUpdated(_primarySaleRecipient);

        vm.prank(deployerSigner);
        tokenContract.setPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: platform fee
    //////////////////////////////////////////////////////////////*/

    function test_state_setPlatformFeeInfo() public {
        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 1000;

        vm.prank(deployerSigner);
        tokenContract.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);

        (address recipient_, uint16 bps) = tokenContract.getPlatformFeeInfo();
        assertEq(_platformFeeRecipient, recipient_);
        assertEq(_platformFeeBps, bps);
    }

    function test_revert_setPlatformFeeInfo_ExceedsMaxBps() public {
        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 10001;

        vm.expectRevert("exceeds MAX_BPS");
        vm.prank(deployerSigner);
        tokenContract.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    function test_revert_setPlatformFeeInfo_NotAuthorized() public {
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.setPlatformFeeInfo(address(1), 1000);
    }

    function test_event_platformFeeInfo() public {
        address _platformFeeRecipient = address(0x123);
        uint256 _platformFeeBps = 1000;

        vm.expectEmit(true, true, true, true);
        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);

        vm.prank(deployerSigner);
        tokenContract.setPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: contract metadata
    //////////////////////////////////////////////////////////////*/

    function test_state_setContractURI() public {
        string memory uri = "uri_string";

        vm.prank(deployerSigner);
        tokenContract.setContractURI(uri);

        string memory _contractURI = tokenContract.contractURI();

        assertEq(_contractURI, uri);
    }

    function test_revert_setContractURI() public {
        bytes32 role = tokenContract.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
        tokenContract.setContractURI("");
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: setTokenURI
    //////////////////////////////////////////////////////////////*/

    function test_setTokenURI_state() public {
        string memory uri = "uri_string";

        vm.prank(deployerSigner);
        tokenContract.setTokenURI(0, uri);

        string memory _tokenURI = tokenContract.tokenURI(0);

        assertEq(_tokenURI, uri);
    }

    function test_setTokenURI_revert_NotAuthorized() public {
        string memory uri = "uri_string";

        vm.expectRevert(abi.encodeWithSelector(NFTMetadata.NFTMetadataUnauthorized.selector));
        vm.prank(address(0x1));
        tokenContract.setTokenURI(0, uri);
    }

    function test_setTokenURI_revert_Frozen() public {
        string memory uri = "uri_string";

        vm.startPrank(deployerSigner);
        tokenContract.freezeMetadata();

        vm.expectRevert(abi.encodeWithSelector(NFTMetadata.NFTMetadataFrozen.selector, 0));
        tokenContract.setTokenURI(0, uri);
    }
}
