// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IByocRegistry {

    struct CustomContract {
        string publishMetadataHash;
        bytes creationCodeHash;
        address implementation;
    }

    struct CustomContractSet {
        uint256 id;
        uint256 removed;
        mapping(uint256 => CustomContract) contractAtId;
    }

    event Paused(bool isPaused);
    event ContractPublished(address indexed publisher, uint256 indexed contractId, CustomContract publishedContract);
    event ContractUnpublished(address indexed caller, address indexed publisher, uint256 indexed contractId);
    event ContractDeployed(address indexed deployer, address indexed publisher, uint256 indexed contractId, address deployedContract);

    /// @notice Returns all contracts published by a publisher.
    function getPublishedContracts(address publisher) external view returns (CustomContract[] memory);

    /// @notice Add a contract to a publisher's set of published contracts.
    function publishContract(string memory publishMetadataHash, bytes memory creationCodeHash, address implementation) external returns (uint256 contractId);

    /// @notice Remove a contract from a publisher's set of published contracts.
    function unpublishContract(address publisher, uint256 contractId) external;

    /// @notice Deploys an instance of a published contract directly.
    function deployInstance(
        address publisher,
        uint256 contractId,
        bytes memory creationCode,
        bytes memory data,
        bytes32 salt,
        uint256 _value
    ) external returns (address deployedAddress);

    /// @notice Deploys a clone pointing to an implementation of a published contract.
    function deployInstanceProxy(
        address publisher,
        uint256 contractId,
        bytes memory data,
        bytes32 salt
    ) external returns (address deployedAddress);
}