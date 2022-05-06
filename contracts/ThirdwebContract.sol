// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./feature/Ownable.sol";
import "./feature/ContractMetadata.sol";

contract ThirdwebContract is Ownable, ContractMetadata {
    struct ThirdwebInfo {
        string publishMetadataUri;
        string contractURI;
        address owner;
    }

    /// @dev The publish metadata of the contract of which this contract is an instance.
    string private publishMetadataUri;

    /// @dev Returns the publish metadata for this contract.
    function getPublishMetadataUri() external view returns (string memory) {
        return publishMetadataUri;
    }

    /// @dev Initializes the publish metadata and contract metadata at deploy time.
    function setThirdwebInfo(ThirdwebInfo memory _thirdwebInfo) external {
        require(bytes(publishMetadataUri).length == 0, "Published metadata already initialized");
        require(owner == address(0), "Owner already initialized");

        publishMetadataUri = _thirdwebInfo.publishMetadataUri;
        contractURI = _thirdwebInfo.contractURI;
        owner = _thirdwebInfo.owner;
    }

    /// @dev Returns whether owner can be set
    function _canSetOwner() internal virtual override returns (bool) {
        return msg.sender == owner;
    }

    /// @dev Returns whether contract metadata can be set
    function _canSetContractURI() internal virtual override returns (bool) {
        return msg.sender == owner;
    }
}
