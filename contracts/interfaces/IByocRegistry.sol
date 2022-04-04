// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IByocRegistry {

    /**
     *  @notice The data stored for a published contract.
     *
     *  @param contractId The integer identifier of this published contract. (publisher address, contractId) => published contract.
     *  @param publishMetadataUri The IPFS URI of the publish metadata.
     *  @param bytecodeHash The keccak256 hash of the contract bytecode.
     *  @param implementation (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                        if such an implementation does not exist - address(0);
     */
    struct CustomContract {
        uint256 contractId;
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

    /// @dev Emitted when the registry is paused. Only unpublishing is allowed when the registry is paused.
    event Paused(bool isPaused);
    /// @dev Emitted when a contract is published.
    event ContractPublished(address indexed publisher, uint256 indexed contractId, CustomContract publishedContract);
    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed caller, address indexed publisher, uint256 indexed contractId);
    /// @dev Emitted when a contract is deployed.
    event ContractDeployed(address indexed deployer, address indexed publisher, uint256 indexed contractId, address deployedContract);

    /**
     *  @notice Returns all contracts published by a publisher.
     *
     *  @param publisher The address of the publisher.
     *
     *  @return published An array of all contracts published by the publisher.
     */
    function getPublishedContracts(address publisher) external view returns (CustomContract[] memory published);

    /**
     *  @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher The address of the publisher.
     *  @param publishMetadataUri The IPFS URI of the publish metadata.
     *  @param bytecodeHash The keccak256 hash of the contract bytecode.
     *  @param implementation (Optional) An implementation address that proxy contracts / clones can point to. Default value
     *                        if such an implementation does not exist - address(0);
     *
     *  @return contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     */
    function publishContract(address publisher, string memory publishMetadataUri, bytes memory bytecodeHash, address implementation) external returns (uint256 contractId);

    /**
     *  @notice Let's an account unpublish a contract. The account must be approved by the publisher, or be the publisher.
     *
     *  @param publisher The address of the publisher. 
     *  @param contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     */
    function unpublishContract(address publisher, uint256 contractId) external;

    /**
     *  @notice Deploys an instance of a published contract directly.
     *
     *  @param publisher The address of the publisher. 
     *  @param contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     *  @param contractBytecode The bytecode of the contract to deploy.
     *  @param constructorArgs The encoded constructor args to deploy the contract with.
     *  @param salt The salt to use in the CREATE2 contract deployment.
     *  @param value The native token value to pass to the contract on deployment.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstance(
        address publisher,
        uint256 contractId,
        bytes memory contractBytecode,
        bytes memory constructorArgs,
        bytes32 salt,
        uint256 value
    ) external returns (address deployedAddress);

    /**
     *  @notice Deploys a clone pointing to an implementation of a published contract.
     *
     *  @param publisher The address of the publisher. 
     *  @param contractId The unique integer identifier of the published contract. (publisher address, contractId) => published contract.
     *  @param initializeArgs The encoded args to initialize the contract with.
     *  @param salt The salt to use in the CREATE2 contract deployment.
     *  @param value The native token value to pass to the contract on deployment.
     *
     *  @return deployedAddress The address of the contract deployed.
     */
    function deployInstanceProxy(
        address publisher,
        uint256 contractId,
        bytes memory initializeArgs,
        bytes32 salt,
        uint256 value
    ) external returns (address deployedAddress);
}