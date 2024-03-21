// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenERC721Alt } from "contracts/prebuilts/token/TokenERC721Alt.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

// Test imports
import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TokenERC721AltBenchmarkTest is BaseTest {
    using Strings for uint256;

    event TokensMinted(address indexed mintedTo, uint256 indexed tokenIdMinted, string uri);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        uint256 indexed tokenIdMinted,
        TokenERC721Alt.MintRequest mintRequest
    );
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);

    TokenERC721Alt public tokenContract;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    bytes private emptyEncodedBytes = abi.encode("", "");

    TokenERC721Alt.MintRequest _mintrequest;
    bytes _signature;

    address internal deployerSigner;
    address internal recipient;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        recipient = address(0x123);
        address _imp = address(new TokenERC721Alt());
        tokenContract = TokenERC721Alt(
            address(
                new TWProxy(
                    _imp,
                    abi.encodeCall(
                        TokenERC721Alt.initialize,
                        (deployerSigner, NAME, SYMBOL, CONTRACT_URI, forwarders(), royaltyRecipient, royaltyBps)
                    )
                )
            )
        );

        typehashMintRequest = keccak256(
            "MintRequest(address to,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
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
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        TokenERC721Alt.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
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
                        Benchmark: TokenERC721Alt
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_tokenERC721Alt_mintWithSignature_oneToken() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        _signature = signMintRequest(_mintrequest, privateKey);

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_benchmark_tokenERC721Alt_mintWithSignature_fiveTokensMulticall() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        bytes[] memory calls = new bytes[](5);
        for (uint256 i = 0; i < 5; i++) {
            _mintrequest.uid = bytes32(i);
            _signature = signMintRequest(_mintrequest, privateKey);

            calls[i] = abi.encodeWithSelector(TokenERC721Alt.mintWithSignature.selector, _mintrequest, _signature);
        }

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.multicall(calls);
    }

    function test_benchmark_tokenERC721Alt_mintWithSignature_tenTokensMulticall() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        bytes[] memory calls = new bytes[](10);
        for (uint256 i = 0; i < 10; i++) {
            _mintrequest.uid = bytes32(i);
            _signature = signMintRequest(_mintrequest, privateKey);

            calls[i] = abi.encodeWithSelector(TokenERC721Alt.mintWithSignature.selector, _mintrequest, _signature);
        }

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.multicall(calls);
    }
}
