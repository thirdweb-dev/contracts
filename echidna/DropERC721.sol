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

    function grantRole(address _account) public {
        drop.grantRole(drop.DEFAULT_ADMIN_ROLE(), _account);
    }

    function revokeRole(address _account) public {
        drop.revokeRole(drop.DEFAULT_ADMIN_ROLE(), _account);
    }

    function renounceRole(address _account) public {
        drop.renounceRole(drop.DEFAULT_ADMIN_ROLE(), _account);
    }

    function setOwner(address _newOwner) public {
        drop.setOwner(_newOwner);
    }

    function isAdmin(address _account) public view returns (bool) {
        return drop.hasRole(drop.DEFAULT_ADMIN_ROLE(), _account);
    }
}

contract EchidnaDropERC721 is DropERC721Proxy {
    address public __owner;
    bool public __isAdmin;

    constructor() DropERC721Proxy() {
        set_input_owner(msg.sender);
        set_input_admin(msg.sender);
    }

    function set_input_owner(address owner) public {
        __owner = drop.owner() == owner ? owner : address(0);
    }

    function set_input_admin(address account) public {
        __isAdmin = isAdmin(account);
    }

    function echidna_owner_has_admin() public returns (bool) {
        return __isAdmin && __owner != address(0);
    }

    function echidna_deployer_is_admin() public returns (bool) {
        return __owner == DEPLOYER && __isAdmin && isAdmin(DEPLOYER);
    }

    function echidna_msg_sender() public returns (bool) {
        return __owner == msg.sender && __isAdmin && isAdmin(msg.sender);
    }
}
