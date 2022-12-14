// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IEntrypoint.sol";

interface IEntrypointOverrideable is IEntrypoint {
    struct ExtensionMap {
        bytes4 selector;
        address extension;
    }

    function overrideExtensionForFunction(bytes4 _selector, address _extension) external;

    function getAllOverriden() external view returns (ExtensionMap[] memory functionExtensionPairs);
}
