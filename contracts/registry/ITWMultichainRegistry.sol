// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface ITWMultichainRegistry {
    struct Deployment {
        address deploymentAddress;
        uint256 chainId;
        string metadataURI;
    }

    event Added(address indexed deployer, address indexed deployment, uint256 indexed chainId, string metadataUri);
    event Deleted(address indexed deployer, address indexed deployment, uint256 indexed chainId);

    /// @notice Add a deployment for a deployer.
    function add(
        address _deployer,
        address _deployment,
        uint256 _chainId,
        string memory metadataUri
    ) external;

    /// @notice Remove a deployment for a deployer.
    function remove(
        address _deployer,
        address _deployment,
        uint256 _chainId
    ) external;

    /// @notice Get all deployments for a deployer.
    function getAll(address _deployer) external view returns (Deployment[] memory allDeployments);

    /// @notice Get the total number of deployments for a deployer.
    function count(address _deployer) external view returns (uint256 deploymentCount);

    /// @notice Returns the metadata IPFS URI for a deployment on a given chain if previously registered via add().
    function getMetadataUri(uint256 _chainId, address _deployment) external view returns (string memory metadataUri);
}
