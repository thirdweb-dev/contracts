// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// CREATE2 -- contract deployment.
import "@openzeppelin/contracts/utils/Create2.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Protocol Components
import { Forwarder } from "./Forwarder.sol";
import { ProtocolControl } from "./ProtocolControl.sol";

contract Registry is Ownable {

    // Mapping from deployer => `ProtocolControl`
    mapping(address => address) public protocolControl;
    // Mapping from deployer => `Forwarder`
    mapping(address => address) public forwarder;

    // Emitted on protocol deployment
    event DeployedProtocol(address indexed deployer, address indexed protocolControl, address indexed forwarder);

    constructor() {}

    /// @dev Deploys the control center, pack and market components of the protocol.
    function deployProtocol() external {
        
        bytes32 salt = keccak256(abi.encodePacked(block.number, msg.sender));

        // Deploy `Forwarder`
        address forwarderAddress = forwarder[msg.sender];

        if(forwarderAddress == address(0)) {
            bytes memory forwarderByteCode = abi.encodePacked(type(Forwarder).creationCode);
            address forwarderAddr = Create2.deploy(0, salt, forwarderByteCode);

            forwarder[msg.sender] = forwarderAddr;
            forwarderAddress = forwarderAddr;
        }

        // Deploy `ProtocolControl`
        bytes memory protocolControlByteCode = abi.encodePacked(type(ProtocolControl).creationCode, abi.encode(msg.sender));

        address protocolControlAddr = Create2.deploy(0, salt, protocolControlByteCode);
        protocolControl[msg.sender] = protocolControlAddr;

        emit DeployedProtocol(msg.sender, protocolControlAddr, forwarderAddress);
    }
}
