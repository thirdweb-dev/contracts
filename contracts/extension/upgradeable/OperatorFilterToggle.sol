// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/interface/IOperatorFilterToggle.sol";

library OperatorFilterToggleStorage {
    bytes32 public constant OPERATOR_FILTER_TOGGLE_STORAGE_POSITION = keccak256("operator.filter.toggle.storage");

    struct Data {
        bool operatorRestriction;
    }

    function operatorFilterToggleStorage() internal pure returns (Data storage operatorFilterToggleData) {
        bytes32 position = OPERATOR_FILTER_TOGGLE_STORAGE_POSITION;
        assembly {
            operatorFilterToggleData.slot := position
        }
    }
}

abstract contract OperatorFilterToggle is IOperatorFilterToggle {
    function operatorRestriction() external view override returns (bool) {
        OperatorFilterToggleStorage.Data storage data = OperatorFilterToggleStorage.operatorFilterToggleStorage();
        return data.operatorRestriction;
    }

    function setOperatorRestriction(bool _restriction) external {
        require(_canSetOperatorRestriction(), "Not authorized to set operator restriction.");
        _setOperatorRestriction(_restriction);
    }

    function _setOperatorRestriction(bool _restriction) internal {
        OperatorFilterToggleStorage.Data storage data = OperatorFilterToggleStorage.operatorFilterToggleStorage();

        data.operatorRestriction = _restriction;
        emit OperatorRestriction(_restriction);
    }

    function _canSetOperatorRestriction() internal virtual returns (bool);
}
