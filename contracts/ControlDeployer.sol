// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IControlDeployer.sol";

import { Registry } from "./Registry.sol";
import { Royalty } from "./Royalty.sol";
import { ProtocolControl } from "./ProtocolControl.sol";

contract ControlDeployer is AccessControl, IControlDeployer {
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function deployControl(
        address registry,
        uint256 nonce,
        address deployer,
        string memory uri
    ) external override returns (address) {
        require(hasRole(REGISTRY_ROLE, msg.sender), "caller not a registry");
        require(hasRole(REGISTRY_ROLE, registry), "invalid registry");

        // protocol control deployment
        bytes memory controlBytecode = abi.encodePacked(
            type(ProtocolControl).creationCode,
            abi.encode(registry, deployer, uri)
        );

        // CREATE2: new_address = hash(0xFF, sender, salt, bytecode)
        bytes32 salt = keccak256(abi.encodePacked(registry, deployer, nonce));
        address control = Create2.deploy(0, salt, controlBytecode);

        // royalty deployment
        emit DeployedControl(registry, deployer, control);

        return control;
    }
}
