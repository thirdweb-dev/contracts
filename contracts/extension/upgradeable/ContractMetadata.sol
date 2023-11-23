// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IContractMetadata.sol";

/**
 *  @author  thirdweb.com
 *
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

library ContractMetadataStorage {
    /// @custom:storage-location erc7201:contract.metadata.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("contract.metadata.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant CONTRACT_METADATA_STORAGE_POSITION =
        0x4bc804ba64359c0e35e5ed5d90ee596ecaa49a3a930ddcb1470ea0dd625da900;

    struct Data {
        /// @notice Returns the contract metadata URI.
        string contractURI;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = CONTRACT_METADATA_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract ContractMetadata is IContractMetadata {
    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = _contractMetadataStorage().contractURI;
        _contractMetadataStorage().contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @notice Returns the contract metadata URI.
    function contractURI() public view virtual override returns (string memory) {
        return _contractMetadataStorage().contractURI;
    }

    /// @dev Returns the AccountPermissions storage.
    function _contractMetadataStorage() internal pure returns (ContractMetadataStorage.Data storage data) {
        data = ContractMetadataStorage.data();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}
