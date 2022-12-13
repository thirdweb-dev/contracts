// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interface/plugin/IMap.sol";

import "../Multicall.sol";
import "../../openzeppelin-presets/utils/EnumerableSet.sol";

/**
 *  TODO:
 *      - Remove OZ EnumerableSet external dependency.
 */

contract Map is IMap, Multicall {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    EnumerableSet.Bytes32Set private allSelectors;

    mapping(address => EnumerableSet.Bytes32Set) private selectorsForExtension;
    mapping(bytes4 => address) private extension;

    constructor(ExtensionMap[] memory _extensionsToRegister) {
        uint256 len = _extensionsToRegister.length;
        for (uint256 i = 0; i < len; i += 1) {
            _setExtensions(_extensionsToRegister[i].selector, _extensionsToRegister[i].extension);
        }
    }

    function _setExtensions(bytes4 _selector, address _extension) internal {
        require(allSelectors.add(bytes32(_selector)), "REGISTERED");

        extension[_selector] = _extension;
        selectorsForExtension[_extension].add(bytes32(_selector));

        emit ExtensionRegistered(_selector, _extension);
    }

    function getExtensionForFunction(bytes4 _selector) external view returns (address) {
        address ext = extension[_selector];
        require(ext != address(0), "No extension available for selector.");

        return ext;
    }

    function getAllFunctionsOfExtension(address _extension) external view returns (bytes4[] memory registered) {
        uint256 len = selectorsForExtension[_extension].length();
        registered = new bytes4[](len);

        for (uint256 i = 0; i < len; i += 1) {
            registered[i] = bytes4(selectorsForExtension[_extension].at(i));
        }
    }

    function getAllRegistered() external view returns (ExtensionMap[] memory functionExtensionPairs) {
        uint256 len = allSelectors.length();
        functionExtensionPairs = new ExtensionMap[](len);

        for (uint256 i = 0; i < len; i += 1) {
            bytes4 selector = bytes4(allSelectors.at(i));
            functionExtensionPairs[i] = ExtensionMap(selector, extension[selector]);
        }
    }
}
