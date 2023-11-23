// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ITWRegistry {
    struct Deployment {
        address deploymentAddress;
        uint256 chainId;
    }

    event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId);
    event Deleted(address indexed deployer, address indexed deployment, uint256 indexed chainId);

    /// @notice Add a deployment for a deployer.
    function add(address _deployer, address _deployment, uint256 _chainId) external;

    /// @notice Remove a deployment for a deployer.
    function remove(address _deployer, address _deployment, uint256 _chainId) external;

    /// @notice Get all deployments for a deployer.
    function getAll(address _deployer) external view returns (Deployment[] memory allDeployments);

    /// @notice Get the total number of deployments for a deployer.
    function count(address _deployer) external view returns (uint256 deploymentCount);
}
