// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract ThirdwebContract {
    /// @dev The publish metadata of the contract of which this contract is an instance.
    string private publishMetadataUri;

    /// @dev The address of the thirdweb factory.
    address private immutable factory;

    constructor() {
        factory = msg.sender;
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
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }
}
