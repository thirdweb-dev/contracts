// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./feature/Ownable.sol";
import "./feature/Context.sol";
import "./feature/ContractMetadata.sol";

contract ThirdwebContract is Context, Ownable, ContractMetadata {

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
        require(bytes(publishMetadataUri).length == 0, "Already initialized");

        publishMetadataUri = _thirdwebInfo.publishMetadataUri;
        contractURI = _thirdwebInfo.contractURI;
        owner = _thirdwebInfo.owner;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal virtual override returns (bool) {
        return _msgSender() == owner;
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal virtual override returns (bool) {
        return _msgSender() == owner;
    }
}
