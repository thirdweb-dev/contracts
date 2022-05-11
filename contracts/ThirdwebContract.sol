// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IDeployer {
    function deployer() external view returns (address);
}

contract ThirdwebContract {
    /// @dev The publish metadata of the contract of which this contract is an instance.
    string private publishMetadataUri;

    /// @dev The address of the thirdweb factory.
    address private factory;

    /// @dev Address of the contract deployer.
    address private deployer;

    constructor() {
        factory = msg.sender;
        deployer = IDeployer(msg.sender).deployer();
    }

    /// @dev Returns the publish metadata for this contract.
    function getPublishMetadataUri() external view returns (string memory) {
        return publishMetadataUri;
    }

    /// @dev Initializes the publish metadata and at deploy time.
    function setPublisheMetadataUi(string memory uri) external {
        require(bytes(publishMetadataUri).length == 0, "Published metadata already initialized");
        publishMetadataUri = uri;
    }

    /// @dev Returns msg.sender, if caller is not thirdweb factory. Returns the intended msg.sender if caller is factory.
    function _thirdwebMsgSender() internal view returns (address sender) {
        if (msg.sender == factory) {
            sender = deployer;
        } else {
            sender = msg.sender;
        }
    }
}
