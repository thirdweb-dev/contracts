// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../../contracts/interfaces/IContractPublisher.sol";

// solhint-disable const-name-snakecase
contract MockContractPublisher is IContractPublisher {
    function getAllPublishedContracts(address publisher)
        external
        view
        override
        returns (CustomContractInstance[] memory published)
    {
        CustomContractInstance[] memory mocks = new CustomContractInstance[](1);
        mocks[0] = CustomContractInstance(
            "MockContract",
            123,
            "ipfs://mock",
            0x0000000000000000000000000000000000000000000000000000000000000001,
            address(0x0000000000000000000000000000000000000000)
        );
        return mocks;
    }

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
        returns (CustomContractInstance[] memory published)
    {
        return new CustomContractInstance[](0);
    }

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
        returns (CustomContractInstance memory published)
    {
        return CustomContractInstance("", 0, "", "", address(0));
    }

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
    ) external {}

    /**
     *  @notice Lets a publisher unpublish a contract and all its versions.
     *
     *  @param publisher  The address of the publisher.
     *  @param contractId The identifier for a published contract (that can have multiple verisons).
     */
    function unpublishContract(address publisher, string memory contractId) external {}

    /**
     * @notice Lets an account set its publisher profile uri
     */
    function setPublisherProfileUri(address publisher, string memory uri) external {}

    /**
     * @notice Get the publisher profile uri for a given publisher.
     */
    function getPublisherProfileUri(address publisher) external view returns (string memory uri) {
        return "";
    }

    /**
     * @notice Retrieve the published metadata URI from a compiler metadata URI.
     */
    function getPublishedUriFromCompilerUri(string memory compilerMetadataUri)
        external
        view
        returns (string[] memory publishedMetadataUris)
    {
        return new string[](0);
    }
}
