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
    // NFTLabs admin signer
    address public providerAdmin;
    address public providerTreasury;

    // `Forwarder` for meta-transacitons
    address public forwarder;

    struct ControlCenters {
        // Total number of versions
        uint256 latestVersion;
        // Version number => protocol control center address
        mapping(uint256 => address) protocolControl;
    }

    // Mapping from app deployer => app address.
    mapping(address => ControlCenters) public controlCenters;

    // Emitted on protocol deployment
    event DeployedProtocol(address indexed deployer, address indexed protocolControl, uint256 version);
    // Emitted in constructor
    event DeployedForwarder(address forwarder);
    // Emitted when the NFTLabs admin signer is updated
    event UpdatedProviderAdmin(address prevAdmin, address newAdmin);
    event UpdatedProviderTreasury(address prevTreasury, address newTreasury);

    constructor(address _admin, address _treasury) {
        providerAdmin = _admin;
        providerTreasury = _treasury;

        // Deploy forwarder for meta-transactions
        bytes32 salt = keccak256(abi.encodePacked(block.number, msg.sender));
        bytes memory forwarderByteCode = abi.encodePacked(type(Forwarder).creationCode);
        forwarder = Create2.deploy(0, salt, forwarderByteCode);

        emit DeployedForwarder(forwarder);
    }

    /// @dev Deploys the control center, pack and market components of the protocol.
    function deployProtocol(string memory _protocolControlURI) external {
        bytes32 salt = keccak256(abi.encodePacked(block.number, msg.sender));

        // Deploy `ProtocolControl`
        bytes memory protocolControlByteCode = abi.encodePacked(
            type(ProtocolControl).creationCode,
            abi.encode(msg.sender, providerAdmin, providerTreasury, _protocolControlURI)
        );

        address protocolControlAddr = Create2.deploy(0, salt, protocolControlByteCode);

        uint256 currentVersion = controlCenters[msg.sender].latestVersion;
        controlCenters[msg.sender].protocolControl[currentVersion] = protocolControlAddr;
        controlCenters[msg.sender].latestVersion += 1;

        emit DeployedProtocol(msg.sender, protocolControlAddr, currentVersion);
    }

    /// @dev Lets the owner of the contract update the NFTLabs admin signer
    function setProviderAdmin(address _newAdminSigner) external onlyOwner {
        address prevAdmin = providerAdmin;
        providerAdmin = _newAdminSigner;

        emit UpdatedProviderAdmin(prevAdmin, _newAdminSigner);
    }

    function setProviderTreasury(address _newTreasury) external onlyOwner {
        address prevTreasury = providerTreasury;
        providerTreasury = _newTreasury;

        emit UpdatedProviderTreasury(prevTreasury, _newTreasury);
    }

    /// @dev Returns the latest version of protocol control
    function getLatestVersion(address _protocolDeployer) external view returns (uint256) {
        return controlCenters[_protocolDeployer].latestVersion;
    }

    /// @dev Returns the protocol control address for the given version
    function getProtocolControl(address _protocolDeployer, uint256 _version) external view returns (address) {
        return controlCenters[_protocolDeployer].protocolControl[_version];
    }
}
