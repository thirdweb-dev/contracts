// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IByocRegistry {

    /**
     *  @notice The data stored for a published contract.
     *
     *  @param contractId The integer identifier of this published contract. (publisher address, contractId) => published contract.
     *  @param  groupId The identifier for the group of published contracts that this published contract belongs to.
     *  @param publishMetadataUri The IPFS URI of the publish metadata.
     *  @param bytecodeHash The keccak256 hash of the contract bytecode.
     *  @param implementation (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                        if such an implementation does not exist - address(0);
     */
    struct CustomContract {
        uint256 contractId;
        bytes32 groupId;
        string publishMetadataUri;
        bytes32 bytecodeHash;
        address implementation;
    }

    /// @dev The set of all contracts published by a publisher.
    struct CustomContractSet {
        uint256 id;
        uint256 removed;
        mapping(uint256 => CustomContract) contractAtId;
    }

    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);
    /// @dev Emitted when a publisher's approval of an operator is updated.
    event Approved(address indexed publisher, address indexed operator, bool isApproved);
    /// @dev Emitted when a contract is published.
    event ContractPublished(address indexed operator, address indexed publisher, uint256 indexed contractId, CustomContract publishedContract);
    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, uint256 indexed contractId);

    /**
     *  @notice Returns whether a publisher has approved an operator to publish / unpublish contracts on their behalf.
     *
     *  @param publisher The address of the publisher.
     *  @param operator The address of the operator who publishes/unpublishes on behalf of the publisher.
     *
     *  @return isApproved Whether the publisher has approved the operator to publish / unpublish contracts on their behalf.
     */
    function isApprovedByPublisher(address publisher, address operator) external view returns (bool isApproved);

    /**
     *  @notice Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.
     *
     *  @param operator The address of the operator who publishes/unpublishes on behalf of the publisher.
     *  @param toApprove whether to an operator to publish / unpublish contracts on the publisher's behalf.
     */
    function approveOperator(address operator, bool toApprove) external;

    /**
     *  @notice Returns all contracts published by a publisher.
     *
     *  @param publisher The address of the publisher.
     *
     *  @return published An array of all contracts published by the publisher.
     */
    function getAllPublishedContracts(address publisher) external view returns (CustomContract[] memory published);

    /**
     *  @notice Returns a group of contracts published by a publisher.
     *
     *  @param publisher The address of the publisher.
     *  @param groupId The identifier for a group of published contracts.
     *
     *  @return published The desired contracts published by the publisher.
     */
    function getPublishedContractGroup(address publisher, bytes32 groupId) external view returns (CustomContract[] memory published);

    /**
     *  @notice Returns a given contract published by a publisher.
     *
     *  @param publisher The address of the publisher.
     *  @param contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     *
     *  @return published The desired contract published by the publisher.
     */
    function getPublishedContract(address publisher, uint256 contractId) external view returns (CustomContract memory published);

    /**
     *  @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher The address of the publisher.
     *  @param publishMetadataUri The IPFS URI of the publish metadata.
     *  @param bytecodeHash The keccak256 hash of the contract bytecode.
     *  @param implementation (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                        if such an implementation does not exist - address(0);
     *  @param  groupId The identifier for the group of published contracts that the contract-to-publish belongs to.
     *
     *  @return contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     */
    function publishContract(address publisher, string memory publishMetadataUri, bytes32 bytecodeHash, address implementation, bytes32 groupId) external returns (uint256 contractId);

    /**
     *  @notice Let's an account unpublish a contract. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher The address of the publisher. 
     *  @param contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     */
    function unpublishContract(address publisher, uint256 contractId) external;
}