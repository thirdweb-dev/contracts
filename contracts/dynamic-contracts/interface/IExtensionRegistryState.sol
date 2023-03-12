// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Interface
import "lib/dynamic-contracts/src/interface/IExtension.sol";

interface IExtensionRegistryState is IExtension {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    struct ExtensionID {
        string name;
        uint256 id;
    }

    struct ExtensionSnapshotData {
        bool isFrozen;
        IExtensionRegistryState.ExtensionID[] allExtensions;
        mapping(bytes32 => IExtension.Extension) extension;
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionForFunction;
    }

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event ExtensionRemoved(string indexed extensionName, Extension extension);
}
