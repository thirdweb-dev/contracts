// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IContractPublisher {
    struct CustomContractInstance {
        string contractId;
        uint256 publishTimestamp;
        string publishMetadataUri;
        bytes32 bytecodeHash;
        address implementation;
    }

    struct CustomContract {
        uint256 total;
        CustomContractInstance latest;
        mapping(uint256 => CustomContractInstance) instances;
    }

    struct CustomContractSet {
        EnumerableSet.Bytes32Set contractIds;
        mapping(bytes32 => CustomContract) contracts;
    }

    struct PublishedMetadataSet {
        uint256 index;
        mapping(uint256 => string) uris;
    }

    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a contract is published.
    event ContractPublished(
        address indexed operator,
        address indexed publisher,
        CustomContractInstance publishedContract
    );

    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, string indexed contractId);

    /// @dev Emitted when a publisher updates their profile URI.
    event PublisherProfileUpdated(address indexed publisher, string prevURI, string newURI);

    /**
     *  @notice Returns the latest version of all contracts published by a publisher.
     *
     *  @param publisher  The address of the publisher.
     *
     *  @return published An array of all contracts published by the publisher.
     */
    function getAllPublishedContracts(
        address publisher
    ) external view returns (CustomContractInstance[] memory published);

    /**
     *  @notice Returns all versions of a published contract.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     *
     *  @return published The desired contracts published by the publisher.
     */
    function getPublishedContractVersions(
        address publisher,
        string memory contractId
    ) external view returns (CustomContractInstance[] memory published);

    /**
     *  @notice Returns the latest version of a contract published by a publisher.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     *
     *  @return published The desired contract published by the publisher.
     */
    function getPublishedContract(
        address publisher,
        string memory contractId
    ) external view returns (CustomContractInstance memory published);

    /**
     *  @notice Let's an account publish a contract.
     *
     *  @param publisher           The address of the publisher.
     *  @param contractId          The identifier for a published contract (that can have multiple verisons).
     *  @param publishMetadataUri  The IPFS URI of the publish metadata.
     *  @param compilerMetadataUri The IPFS URI of the compiler metadata.
     *  @param bytecodeHash        The keccak256 hash of the contract bytecode.
     *  @param implementation      (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                             if such an implementation does not exist - address(0);
     */
    function publishContract(
        address publisher,
        string memory contractId,
        string memory publishMetadataUri,
        string memory compilerMetadataUri,
        bytes32 bytecodeHash,
        address implementation
    ) external;

    /**
     *  @notice Lets a publisher unpublish a contract and all its versions.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     */
    function unpublishContract(address publisher, string memory contractId) external;

    /**
     * @notice Lets an account set its publisher profile uri
     */
    function setPublisherProfileUri(address publisher, string memory uri) external;

    /**
     * @notice Get the publisher profile uri for a given publisher.
     */
    function getPublisherProfileUri(address publisher) external view returns (string memory uri);

    /**
     * @notice Retrieve the published metadata URI from a compiler metadata URI.
     */
    function getPublishedUriFromCompilerUri(
        string memory compilerMetadataUri
    ) external view returns (string[] memory publishedMetadataUris);
}
