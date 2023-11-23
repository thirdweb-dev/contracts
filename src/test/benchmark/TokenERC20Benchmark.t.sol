// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { TokenERC20 } from "contracts/prebuilts/token/TokenERC20.sol";

// Test imports
import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TokenERC20BenchmarkTest is BaseTest {
    using Strings for uint256;

    event TokensMinted(address indexed mintedTo, uint256 quantityMinted);
    event TokensMintedWithSignature(
        address indexed signer,
        address indexed mintedTo,
        TokenERC20.MintRequest mintRequest
    );

    event PrimarySaleRecipientUpdated(address indexed recipient);
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    TokenERC20 public tokenContract;
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;
    bytes32 internal permitTypehash;

    bytes private emptyEncodedBytes = abi.encode("", "");

    TokenERC20.MintRequest _mintrequest;
    bytes _signature;

    address internal deployerSigner;
    address internal recipient;

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        deployerSigner = signer;
        recipient = address(0x123);
        tokenContract = TokenERC20(getContract("TokenERC20"));

        erc20.mint(deployerSigner, 1_000);
        vm.deal(deployerSigner, 1_000);

        erc20.mint(recipient, 1_000);
        vm.deal(recipient, 1_000);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes(NAME));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(tokenContract))
        );
        permitTypehash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        // construct default mintrequest
        _mintrequest.to = recipient;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.quantity = 100;
        _mintrequest.price = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(
        TokenERC20.MintRequest memory _request,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.primarySaleRecipient,
            _request.quantity,
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
                        Benchmark: TokenERC20
    //////////////////////////////////////////////////////////////*/

    function test_benchmark_tokenERC20_mintWithSignature_pay_with_ERC20() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.price = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        // approve erc20 tokens to tokenContract
        vm.prank(recipient);
        erc20.approve(address(tokenContract), _mintrequest.price);

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.mintWithSignature(_mintrequest, _signature);
    }

    function test_benchmark_tokenERC20_mintWithSignature_pay_with_native_token() public {
        vm.pauseGasMetering();
        vm.warp(1000);

        // update mintrequest data
        _mintrequest.price = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        // mint with signature
        vm.prank(recipient);
        vm.resumeGasMetering();
        tokenContract.mintWithSignature{ value: _mintrequest.price }(_mintrequest, _signature);
    }

    function test_benchmark_tokenERC20_mintTo() public {
        vm.pauseGasMetering();
        uint256 _amount = 100;

        vm.prank(deployerSigner);
        vm.resumeGasMetering();
        tokenContract.mintTo(recipient, _amount);
    }
}
