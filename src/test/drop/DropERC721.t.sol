// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/drop/DropERC721.sol";

// Test imports
import "../utils/BaseTest.sol";

contract BaseDropERC721Test is BaseTest {
    DropERC721 public drop;

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    function testHello() public {
        assertEq(drop.name(), "NAME");
    }
}
