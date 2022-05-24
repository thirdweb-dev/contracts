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
        uint256 publicId;
        uint256 total;
        CustomContractInstance latest;
        mapping(uint256 => CustomContractInstance) instances;
    }

    struct CustomContractSet {
        EnumerableSet.Bytes32Set contractIds;
        mapping(bytes32 => CustomContract) contracts;
    }

    struct PublicContract {
        address publisher;
        string contractId;
    }

    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a publisher's approval of an operator is updated.
    event Approved(address indexed publisher, address indexed operator, bool isApproved);

    /// @dev Emitted when a contract is published.
    event ContractPublished(
        address indexed operator,
        address indexed publisher,
        CustomContractInstance publishedContract
    );

    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is added to the public list.
    event AddedContractToPublicList(address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is removed from the public list.
    event RemovedContractToPublicList(address indexed publisher, string indexed contractId);

    /**
     *  @notice Returns whether a publisher has approved an operator to publish / unpublish contracts on their behalf.
     *
     *  @param publisher The address of the publisher.
     *  @param operator  The address of the operator who publishes/unpublishes on behalf of the publisher.
     *
     *  @return isApproved Whether the publisher has approved the operator to publish / unpublish contracts on their behalf.
     */
    function isApprovedByPublisher(address publisher, address operator) external view returns (bool isApproved);

    /**
     *  @notice Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.
     *
     *  @param operator  The address of the operator who publishes/unpublishes on behalf of the publisher.
     *  @param toApprove whether to an operator to publish / unpublish contracts on the publisher's behalf.
     */
    function approveOperator(address operator, bool toApprove) external;

    /**
     *  @notice Returns the latest version of all contracts published by a publisher.
     *
     *  @return published An array of all contracts published by the publisher.
     */
    function getAllPublicPublishedContracts() external view returns (CustomContractInstance[] memory published);

    /**
     *  @notice Returns the latest version of all contracts published by a publisher.
     *
     *  @param publisher  The address of the publisher.
     *
     *  @return published An array of all contracts published by the publisher.
     */
    function getAllPublishedContracts(address publisher)
        external
        view
        returns (CustomContractInstance[] memory published);

    /**
     *  @notice Returns all versions of a published contract.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     *
     *  @return published The desired contracts published by the publisher.
     */
    function getPublishedContractVersions(address publisher, string memory contractId)
        external
        view
        returns (CustomContractInstance[] memory published);

    /**
     *  @notice Returns the latest version of a contract published by a publisher.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     *
     *  @return published The desired contract published by the publisher.
     */
    function getPublishedContract(address publisher, string memory contractId)
        external
        view
        returns (CustomContractInstance memory published);

    /**
     *  @notice Returns the public id of a published contract, if it is public.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     *
     *  @return publicId the public id of a published contract.
     */
    function getPublicId(address publisher, string memory contractId) external returns (uint256 publicId);

    /**
     *  @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher          The address of the publisher.
     *  @param publishMetadataUri The IPFS URI of the publish metadata.
     *  @param bytecodeHash       The keccak256 hash of the contract bytecode.
     *  @param implementation     (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                            if such an implementation does not exist - address(0);
     *  @param  contractId        The identifier for a published contract (that can have multiple verisons).
     *
     */
    function publishContract(
        address publisher,
        string memory publishMetadataUri,
        bytes32 bytecodeHash,
        address implementation,
        string memory contractId
    ) external;

    /**
     *  @notice Lets an account unpublish a contract and all its versions. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     */
    function unpublishContract(address publisher, string memory contractId) external;

    /**
     *  @notice Lets an account add a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     */
    function addToPublicList(address publisher, string memory contractId) external;

    /**
     *  @notice Lets an account remove a published contract (and all its versions). The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     */
    function removeFromPublicList(address publisher, string memory contractId) external;
}
