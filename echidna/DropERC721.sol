// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../contracts/TWProxy.sol";
import "../contracts/drop/DropERC721.sol";
import "./Factory.sol";
import "./Address.sol";

contract DropERC721Proxy is EchidnaAddress {
    EchidnaFactory public factory;
    DropERC721 public drop;
    TWProxy public proxy;

    constructor() {
        factory = new EchidnaFactory();
        proxy = TWProxy(
            payable(
                factory.deployProxy(
                    bytes32("DropERC721"),
                    abi.encodeWithSignature(
                        "initialize(address,string,string,string,address,address,address,uint128,uint128,address)",
                        msg.sender,
                        "",
                        "",
                        "",
                        TRUSTED_FORWARDER,
                        msg.sender,
                        msg.sender,
                        0,
                        0,
                        msg.sender
                    )
                )
            )
        );
        drop = DropERC721(payable(address(proxy)));
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
