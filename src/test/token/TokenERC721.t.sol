// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenERC721 } from "contracts/token/TokenERC721.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TokenERC721Test is BaseTest {
    using StringsUpgradeable for uint256;

    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC721.MintRequest mintRequest
    );
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

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

    function signMintRequest(TokenERC721.MintRequest memory _request, uint256 _privateKey)
        internal
        returns (bytes memory)
    {
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
        assertEq(erc20.balanceOf(recipient), erc20BalanceOfRecipient - _mintrequest.price);
        assertEq(erc20.balanceOf(address(saleRecipient)), erc20BalanceOfSeller + _mintrequest.price);
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
        assertEq(address(recipient).balance, etherBalanceOfRecipient - _mintrequest.price);
        assertEq(address(saleRecipient).balance, etherBalanceOfSeller + _mintrequest.price);
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
                TWStrings.toHexString(uint160(address(0x1)), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
        );
        vm.prank(address(0x1));
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

        vm.expectRevert("ERC721: owner query for nonexistent token");
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

        vm.expectRevert("ERC721: owner query for nonexistent token");
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
}
