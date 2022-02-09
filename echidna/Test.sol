// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../contracts/TWFee.sol";
import "../contracts/TWProxy.sol";
import "../contracts/drop/DropERC721.sol";

contract DropERC721Proxy {
    TWFee public fee;
    DropERC721 public drop;
    TWProxy public proxy;

    constructor() {
        fee = new TWFee(address(0x10), address(0x11), address(0x12), 0, 0);
        drop = new DropERC721(address(fee));
        proxy = new TWProxy(address(drop), "");
    }
}

contract EchidnaDropERC721 is DropERC721Proxy {
    uint256 public v;

    constructor() DropERC721Proxy() {}

    function set(uint256 x) public {
        v = x;
    }

    function a() public view returns (uint256) {
        assert(v == 42);
        return v;
    }

    function echidna_as() public returns (bool) {
        return v == 0;
    }
}
