// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IOperatorFilterToggle.sol";

library OperatorFilterToggleStorage {
    /// @custom:storage-location erc7201:operator.filter.toggle.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("operator.filter.toggle.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant OPERATOR_FILTER_TOGGLE_STORAGE_POSITION =
        0xc9c6c05578224a00a593ea5c05021a182582a08fc1143a677c61a8fe56c23800;

    struct Data {
        bool operatorRestriction;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = OPERATOR_FILTER_TOGGLE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract OperatorFilterToggle is IOperatorFilterToggle {
    function operatorRestriction() external view override returns (bool) {
        return _operatorFilterToggleStorage().operatorRestriction;
    }

    function setOperatorRestriction(bool _restriction) external {
        require(_canSetOperatorRestriction(), "Not authorized to set operator restriction.");
        _setOperatorRestriction(_restriction);
    }

    function _setOperatorRestriction(bool _restriction) internal {
        _operatorFilterToggleStorage().operatorRestriction = _restriction;
        emit OperatorRestriction(_restriction);
    }

    /// @dev Returns the OperatorFilterToggle storage.
    function _operatorFilterToggleStorage() internal pure returns (OperatorFilterToggleStorage.Data storage data) {
        data = OperatorFilterToggleStorage.data();
    }

    function _canSetOperatorRestriction() internal virtual returns (bool);
}
