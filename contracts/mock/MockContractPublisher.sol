// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../interfaces/IContractPublisher.sol";

// solhint-disable const-name-snakecase
contract MockContractPublisher is IContractPublisher {
    function getAllPublishedContracts(address)
        external
        pure
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

    function getPublishedContractVersions(address, string memory)
        external
        pure
        returns (CustomContractInstance[] memory published)
    {
        return new CustomContractInstance[](0);
    }

    function getPublishedContract(address, string memory)
        external
        pure
        returns (CustomContractInstance memory published)
    {
        return CustomContractInstance("", 0, "", "", address(0));
    }

    function publishContract(
        address publisher,
        string memory contractId,
        string memory publishMetadataUri,
        string memory compilerMetadataUri,
        bytes32 bytecodeHash,
        address implementation
    ) external {}

    function unpublishContract(address publisher, string memory contractId) external {}

    function setPublisherProfileUri(address, string memory) external {}

    function getPublisherProfileUri(address) external pure returns (string memory uri) {
        return "";
    }

    function getPublishedUriFromCompilerUri(string memory)
        external
        pure
        returns (string[] memory publishedMetadataUris)
    {
        return new string[](0);
    }
}
