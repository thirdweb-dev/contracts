// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Thirdweb Proxy
import { ThirdwebProxy } from "./ThirdwebProxy.sol";

// Utils
import "@openzeppelin/contracts/utils/Create2.sol";

contract ThirdwebFactory {

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address indexed proxy, address indexed deployer);

    constructor() {}

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxy(address _implementation,bytes memory _data) external {

        // TODO: where to store: 'this deployer owns / has deployed this proxy?'
        // TODO: should implement a check whether `_implementation` is a contract deployed via thirdweb?

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(_implementation, _data)
        );
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        address deployedProxy = Create2.deploy(0, salt, proxyBytecode);

        emit ProxyDeployed(_implementation, deployedProxy, msg.sender);
    }

    /// @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
    function deployProxyDeterministic(address _implementation,bytes memory _data, bytes32 _salt) external {

        // TODO: where to store: 'this deployer owns / has deployed this proxy?'
        // TODO: should implement a check whether `_implementation` is a contract deployed via thirdweb?

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(_implementation, _data)
        );

        address deployedProxy = Create2.deploy(0, _salt, proxyBytecode);

        emit ProxyDeployed(_implementation, deployedProxy, msg.sender);
    }
}