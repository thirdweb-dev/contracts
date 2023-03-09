// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/core/Router.sol";

import "../interface/IExtensionRegistry.sol";

contract ExampleRouter is Router {
    address public immutable implementationAddress;
    address public immutable extensionRegistry;

    constructor(address _extensionRegistry, string memory _extensionSetId) {
        extensionRegistry = _extensionRegistry;
        implementationAddress = address(this);

        IExtensionRegistry(_extensionRegistry).registerRouter(_extensionSetId);
    }

    /// @dev Unimplemented. Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        return IExtensionRegistry(extensionRegistry).getExtensionForFunction(_functionSelector, implementationAddress);
    }
}
