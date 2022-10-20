// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IMap.sol";

import "../extension/Multicall.sol";
import "./extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Map is IMap, Multicall, PermissionsEnumerable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    EnumerableSet.Bytes32Set private allSelectors;

    mapping(bytes4 => address) private extension;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function setExtension(bytes4 _selector, address _extension) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "!OPERATOR_ROLE");

        extension[_selector] = _extension;

        emit ExtensionRegistered(_selector, _extension);
    }

    function getExtension(bytes4 _selector) external view returns (address) {
        address ext = extension[_selector];
        require(ext != address(0), "No extension available for selector.");

        return ext;
    }

    function getAllSelectorsRegistered() external view returns (bytes4[] memory selectors) {
        uint256 len = allSelectors.length();
        selectors = new bytes4[](len);

        for (uint256 i = 0; i < len; i += 1) {
            selectors[i] = bytes4(allSelectors.at(i));
        }
    }
}
