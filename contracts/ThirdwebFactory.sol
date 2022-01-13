// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Thirdweb contracts
import "./ThirdwebProxy.sol";
import "./ThirdwebRegistry.sol"; 

// Utils
import "@openzeppelin/contracts/utils/Create2.sol";

contract ThirdwebFactory {

    address public thirdwebRegistry;

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address indexed proxy, address indexed deployer);

    mapping(bytes32 => mapping(uint256 => address)) public modules;

    constructor() {
        bytes memory registryBytecode = abi.encodePacked(
            type(ThirdwebRegistry).creationCode,
            abi.encode(address(this))
        );

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        thirdwebRegistry = Create2.deploy(0, salt, registryBytecode);
    }

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxy(bytes32 _moduleType, uint256 _version, bytes memory _data) external {

        address implementation = modules[_moduleType][_version];

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(implementation, _data)
        );
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        address deployedProxy = Create2.deploy(0, salt, proxyBytecode);

        ThirdwebRegistry(thirdwebRegistry).updateDeployments(_moduleType, deployedProxy, msg.sender);

        emit ProxyDeployed(implementation, deployedProxy, msg.sender);
    }

    /// @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
    function deployProxyDeterministic(bytes32 _moduleType, uint256 _version, bytes memory _data, bytes32 _salt) external {

        address implementation = modules[_moduleType][_version];

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(implementation, _data)
        );

        address deployedProxy = Create2.deploy(0, _salt, proxyBytecode);

        ThirdwebRegistry(thirdwebRegistry).updateDeployments(_moduleType, deployedProxy, msg.sender);

        emit ProxyDeployed(implementation, deployedProxy, msg.sender);
    }
}