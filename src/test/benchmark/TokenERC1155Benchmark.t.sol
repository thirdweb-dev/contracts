// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenERC1155, IPlatformFee } from "contracts/prebuilts/token/TokenERC1155.sol";

// Test imports
import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TokenERC1155BenchmarkTest is BaseTest {
    using Strings for uint256;

    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri, uint256 quantityMinted);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC1155.MintRequest mintRequest
    );
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);
    event PrimarySaleRecipientUpdated(address indexed recipient);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    TokenERC1155 public tokenContract;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    bytes private emptyEncodedBytes = abi.encode("", "");

    TokenERC1155.MintRequest _mintrequest;
    bytes _signature;

    address internal deployerSigner;
    address internal recipient;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        recipient = address(0x123);
        tokenContract = TokenERC1155(getContract("TokenERC1155"));

        erc20.mint(deployerSigner, 1_000);
        vm.deal(deployerSigner, 1_000);

        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("TokenERC1155"));
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
        _mintrequest.tokenId = type(uint256).max;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 100;
        _mintrequest.pricePerToken = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        TokenERC1155.MintRequest memory _request,
        uint256 _privateKey
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    /*///////////////////////////////////////////////////////////////
                        Benchmark: TokenERC1155
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_tokenERC1155_mintWithSignature_pay_with_ERC20() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        // approve erc20 tokens to tokenContract
        vm.prank(recipient);
        erc20.approve(address(tokenContract), _mintrequest.pricePerToken * _mintrequest.quantity);

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_benchmark_tokenERC1155_mintWithSignature_pay_with_native_token() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.mintWithSignature{ value: _mintrequest.pricePerToken * _mintrequest.quantity }(
            _mintrequest,
            _signature
        );
    }

    function test_benchmark_tokenERC1155_mintTo() public {
        vm.pauseGasMetering();
        string memory _tokenURI = "tokenURI";
        uint256 _amount = 100;

        vm.prank(deployerSigner);
        vm.resumeGasMetering();
        tokenContract.mintTo(recipient, type(uint256).max, _tokenURI, _amount);
    }

    function test_benchmark_tokenERC1155_burn() public {
        vm.pauseGasMetering();
        string memory _tokenURI = "tokenURI";
        uint256 _amount = 100;

        uint256 nextTokenId = tokenContract.nextTokenIdToMint();

        vm.prank(deployerSigner);
        tokenContract.mintTo(recipient, type(uint256).max, _tokenURI, _amount);

        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.burn(recipient, nextTokenId, _amount);
    }
}
