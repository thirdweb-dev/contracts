// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../contracts/TWProxy.sol";
import "../contracts/drop/DropERC721.sol";
import "./Factory.sol";
import "./Address.sol";

contract DropERC721Proxy is EchidnaAddress {
    EchidnaFactory public factory;
    DropERC721 public drop;

    constructor() {
        factory = new EchidnaFactory();
        drop = DropERC721(
            payable(
                address(
                    factory.deployProxy(
                        bytes32("DropERC721"),
                        abi.encodeWithSignature(
                            "initialize(address,string,string,string,address,address,address,uint128,uint128,address)",
                            DEPLOYER,
                            "",
                            "",
                            "",
                            TRUSTED_FORWARDER,
                            DEPLOYER,
                            DEPLOYER,
                            0,
                            0,
                            DEPLOYER
                        )
                    )
                )
            )
        );
    }

    function revokeRole(address _account) public {
        if (msg.sender == _account) {
            drop.renounceRole(drop.DEFAULT_ADMIN_ROLE(), _account);
        } else {
            drop.revokeRole(drop.DEFAULT_ADMIN_ROLE(), _account);
        }
    }

    function isAdmin(address _account) public view returns (bool) {
        return drop.hasRole(drop.DEFAULT_ADMIN_ROLE(), _account);
    }
}

contract EchidnaDropERC721 is DropERC721Proxy {
    constructor() DropERC721Proxy() {}

    function set_admin_then_owner(address _newOwner) public {
        drop.grantRole(drop.DEFAULT_ADMIN_ROLE(), _newOwner);
        drop.setOwner(_newOwner);
    }

    function set_owner(address _newOwner) public {
        drop.setOwner(_newOwner);
    }

    function echidna_owner_is_always_an_admin() public returns (bool) {
        if (drop.owner() != address(0)) {
            return isAdmin(drop.owner());
        }
        return true;
    }

    function echidna_deployer_is_always_an_admin() public returns (bool) {
        return drop.owner() == DEPLOYER && isAdmin(DEPLOYER);
    }
}
