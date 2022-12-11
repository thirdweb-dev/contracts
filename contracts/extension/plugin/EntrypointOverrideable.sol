// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IMap.sol";
import "../interface/plugin/IEntrypointOverrideable.sol";
import "../../extension/Multicall.sol";
import "../../openzeppelin-presets/utils/EnumerableSet.sol";

library EntrypointOverrideableStorage {
    bytes32 public constant ENTRYPOINT_OVERRIDEABLE_STORAGE_POSITION = keccak256("entrypoint.overrideable.storage");

    struct Data {
        EnumerableSet.Bytes32Set functions;
        mapping(bytes4 => address) extensionOverride;
    }

    function entrypointStorage() internal pure returns (Data storage entrypointData) {
        bytes32 position = ENTRYPOINT_OVERRIDEABLE_STORAGE_POSITION;
        assembly {
            entrypointData.slot := position
        }
    }
}

abstract contract EntrypointOverrideable is Multicall, IEntrypointOverrideable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    address public immutable functionMap;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _functionMap) {
        functionMap = _functionMap;
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    fallback() external payable virtual {
        address extension = _getExtensionOverride(msg.sig);
        if (extension == address(0)) {
            extension = IMap(functionMap).getExtensionForFunction(msg.sig);
        }

        _delegate(extension);
    }

    receive() external payable {}

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    function overrideExtensionForFunction(bytes4 _selector, address _extension) external {
        require(_canOverrideExtensions(), "Entrypoint: cannot override extensions.");

        EntrypointOverrideableStorage.Data storage data = EntrypointOverrideableStorage.entrypointStorage();
        data.extensionOverride[_selector] = _extension;

        if (_extension != address(0)) {
            data.functions.add(bytes32(_selector));
        } else {
            data.functions.remove(bytes32(_selector));
        }
    }

    function getAllOverriden() external view returns (ExtensionMap[] memory functionExtensionPairs) {
        EntrypointOverrideableStorage.Data storage data = EntrypointOverrideableStorage.entrypointStorage();
        uint256 len = data.functions.length();
        functionExtensionPairs = new ExtensionMap[](len);

        for (uint256 i = 0; i < len; i += 1) {
            bytes4 selector = bytes4(data.functions.at(i));
            functionExtensionPairs[i] = ExtensionMap(selector, data.extensionOverride[selector]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _getExtensionOverride(bytes4 _selector) internal view returns (address) {
        EntrypointOverrideableStorage.Data storage data = EntrypointOverrideableStorage.entrypointStorage();
        return data.extensionOverride[_selector];
    }

    function _canOverrideExtensions() internal view virtual returns (bool);
}
