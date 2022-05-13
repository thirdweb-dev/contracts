// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IContractDeployer {
    function getContractDeployer(address _contract) external view returns (address);
}

error ThirdwebContract_MetadataAlreadyInitialized();

contract ThirdwebContract {
    /// @dev The publish metadata of the contract of which this contract is an instance.
    string private publishMetadataUri;

    /// @dev Returns the publish metadata for this contract.
    function getPublishMetadataUri() external view returns (string memory) {
        return publishMetadataUri;
    }

    /// @dev Initializes the publish metadata and at deploy time.
    function setPublishMetadataUri(string memory uri) external {
        if (bytes(publishMetadataUri).length != 0) {
            revert ThirdwebContract_MetadataAlreadyInitialized();
        }
        publishMetadataUri = uri;
    }

    /// @dev Enable access to the original contract deployer in the constructor. If this function is called outside of a constructor, it will return address(0) instead.
    ///      Save 1 storage slot from not storing the factory address and not having to hardcode the factory address.
    function _contractDeployer() internal view returns (address) {
        if (address(this).code.length == 0) {
            try IContractDeployer(msg.sender).getContractDeployer(address(this)) returns (address deployer) {
                return deployer;
            } catch {
                return address(0);
            }
        }
        return address(0);
    }
}
