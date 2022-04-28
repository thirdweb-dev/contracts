 // SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import { SignatureDropSolmate } from "contracts/signature-drop/SignatureDropSolmate.sol";
import { SignatureDropERC721A } from "contracts/signature-drop/SignatureDropERC721A.sol";
import { SignatureDropERC721 } from "contracts/signature-drop/SignatureDropERC721.sol";
import { SignatureDropEnumerable } from "contracts/signature-drop/SignatureDropEnumerable.sol";

// Test helpers
import { TWProxy } from "contracts/TWProxy.sol";
import { BaseTest } from "./utils/BaseTest.sol";

contract SignatureDropTest is BaseTest {

    SignatureDropEnumerable internal enumerable;
    SignatureDropERC721 internal erc721Oz;
    SignatureDropERC721A internal erc721A;
    SignatureDropSolmate internal solmate;

    address internal _defaultAdmin;
    string internal _name = "Name";
    string internal _symbol = "SYMBOL";
    string internal _contractURI = "ipfs://";
    address[] internal _trustedForwarders = [address(0)];
    address internal _saleRecipient = address(0);
    address internal _royaltyRecipient = address(0);
    uint128 internal _royaltyBps = 500;
    uint128 internal _platformFeeBps = 500;
    address internal _platformFeeRecipient = address(0);

    function getProxyAddress(address impl, bool metadata) internal returns(address proxyAddr) {

        if(metadata) {
            proxyAddr = address(new TWProxy(
                address(impl),
                abi.encodeWithSignature(
                    "initialize(address,string,string,string,address[],address,uint128,uint128,address)",
                    _defaultAdmin,
                    _name,
                    _symbol,
                    _contractURI,
                    _trustedForwarders,
                    _saleRecipient,
                    _royaltyRecipient,
                    _royaltyBps,
                    _platformFeeBps,
                    _platformFeeRecipient
                )
            ));
        } else {
            proxyAddr = address(new TWProxy(
                address(impl),
                abi.encodeWithSignature(
                    "initialize(address,string,address[],address,uint128,uint128,address)",
                    _defaultAdmin,
                    _contractURI,
                    _trustedForwarders,
                    _saleRecipient,
                    _royaltyRecipient,
                    _royaltyBps,
                    _platformFeeBps,
                    _platformFeeRecipient
                )
            ));
        }
        
    }

    function setUp() public override {

        super.setUp();

        // Get each target contract.

        enumerable = new SignatureDropEnumerable(fee);
        // enumerable = SignatureDropEnumerable(getProxyAddress(address(enumerableImpl), true));

        erc721Oz = new SignatureDropERC721(fee);
        // erc721Oz = SignatureDropERC721(getProxyAddress(address(erc721OzImpl), true));

        erc721A = new SignatureDropERC721A(fee);
        // erc721A = SignatureDropERC721A(getProxyAddress(address(erc721AImpl), false));

        solmate = new SignatureDropSolmate(fee);
        // solmate = SignatureDropSolmate(getProxyAddress(address(solmateImpl), false));

        // Lazy mint on each target contract.
        enumerable.lazyMint(100, "ipfs://", abi.encode("", 0));
        erc721Oz.lazyMint(100, "ipfs://", abi.encode("", 0));
        erc721A.lazyMint(100, "ipfs://", abi.encode("", 0));
        solmate.lazyMint(100, "ipfs://", abi.encode("", 0));

        vm.startPrank(address(0x3));
        enumerable.claim(address(0x3), 5, address(0), 0);
        erc721Oz.claim(address(0x3), 5, address(0), 0);
        erc721A.claim(address(0x3), 5, address(0), 0);
        solmate.claim(address(0x3), 5, address(0), 0);
    }

    // function test_claim_1_ERC721Enumerable() public {
    //     enumerable.claim(address(0x5), 1, address(0), 0);
    // }
    // function test_claim_1_ERC721() public {
    //     erc721Oz.claim(address(0x5), 1, address(0), 0);
    // }
    // function test_claim_1_ERC721A() public {
    //     erc721A.claim(address(0x5), 1, address(0), 0);
    // }
    // function test_claim_1_ERC721Solmate() public {
    //     solmate.claim(address(0x5), 1, address(0), 0);
    // }

    // function test_claim_5_ERC721Enumerable() public {
    //     enumerable.claim(address(0x5), 5, address(0), 0);
    // }
    // function test_claim_5_ERC721() public {
    //     erc721Oz.claim(address(0x5), 5, address(0), 0);
    // }
    // function test_claim_5_ERC721A() public {
    //     erc721A.claim(address(0x5), 5, address(0), 0);
    // }
    // function test_claim_5_ERC721Solmate() public {
    //     solmate.claim(address(0x5), 5, address(0), 0);
    // }

    // function test_claim_10_ERC721Enumerable() public {
    //     enumerable.claim(address(0x5), 10, address(0), 0);
    // }
    // function test_claim_10_ERC721() public {
    //     erc721Oz.claim(address(0x5), 10, address(0), 0);
    // }
    // function test_claim_10_ERC721A() public {
    //     erc721A.claim(address(0x5), 10, address(0), 0);
    // }
    // function test_claim_10_ERC721Solmate() public {
    //     solmate.claim(address(0x5), 10, address(0), 0);
    // }

    function test_transferAfterClaim_ERC721Enumerable() public {
        enumerable.safeTransferFrom(address(0x3), address(0x5), 3);
    }
    function test_transferAfterClaim_ERC721() public {
        erc721Oz.safeTransferFrom(address(0x3), address(0x5), 3);
    }
    function test_transferAfterClaim_ERC721A() public {
        erc721A.safeTransferFrom(address(0x3), address(0x5), 3);
    }
    function test_transferAfterClaim_ERC721Solmate() public {
        solmate.safeTransferFrom(address(0x3), address(0x5), 3);
    }
}