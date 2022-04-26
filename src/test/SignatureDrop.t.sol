 // SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import { SignatureDropSolmate } from "contracts/signature-drop/SignatureDropSolmate.sol";
import { SignatureDropERC721A } from "contracts/signature-drop/SignatureDropERC721A.sol";
import { SignatureDropERC721 } from "contracts/signature-drop/SignatureDropERC721.sol";
import { SignatureDropEnumerable } from "contracts/signature-drop/SignatureDropEnumerable.sol";

// Test helpers
import { BaseTest } from "./utils/BaseTest.sol";

contract SignatureDropTest is BaseTest {

    SignatureDropEnumerable internal enumerable;
    SignatureDropERC721 internal erc721;
    SignatureDropERC721A internal erc721A;
    SignatureDropSolmate internal solmate;

    address internal _defaultAdmin;
    string internal _name = "Name";
    string internal _symbol = "SYMBOL";
    string internal _contractURI = "ipfs://";
    address[] _trustedForwarders = [];
    address internal _saleRecipient = address(0);
    address internal _royaltyRecipient = address(0);
    uint128 internal _royaltyBps = 500;
    uint128 internal _platformFeeBps = 500;
    address internal _platformFeeRecipient = address(0);

    function setup() {
        
    }
}