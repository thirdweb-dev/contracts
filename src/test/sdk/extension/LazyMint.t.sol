// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import { LazyMint } from "contracts/extension/LazyMint.sol";

contract MyLazyMint is LazyMint {
    bool condition;

    function setCondition(bool _condition) external {
        condition = _condition;
    }

    function _canLazyMint() internal view override returns (bool) {
        return condition;
    }
}

contract ExtensionLazyMint is DSTest, Test {
    MyLazyMint internal ext;
    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);

    function setUp() public {
        ext = new MyLazyMint();
    }

    function test_state_lazyMint() public {
        ext.setCondition(true);

        string memory uri = "uri_string";
        uint256 batchId = ext.lazyMint(100, uri, "");

        assertEq(batchId, 100);
        assertEq(1, ext.getBaseURICount());

        batchId = ext.lazyMint(200, uri, "");

        assertEq(batchId, 300);
        assertEq(2, ext.getBaseURICount());
    }

    function test_state_lazyMint_NotAuthorized() public {
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintUnauthorized.selector));
        ext.lazyMint(100, "", "");
    }

    function test_state_lazyMint_ZeroAmount() public {
        ext.setCondition(true);
        vm.expectRevert(abi.encodeWithSelector(LazyMint.LazyMintInvalidAmount.selector));
        ext.lazyMint(0, "", "");
    }

    function test_event_lazyMint() public {
        ext.setCondition(true);

        vm.expectEmit(true, true, true, true);
        emit TokensLazyMinted(0, 99, "", "");
        ext.lazyMint(100, "", "");
    }
}
