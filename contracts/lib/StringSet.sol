// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

library StringSet {
    /**
     *  @param _values storage of set values
     *  @param _indexes position of the value in the array + 1. (Note: index 0 means a value is not in the set.)
     */
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /// @dev Add a value to a set.
    ///      Returns `true` if the value is not already present in set.
    function _add(Set storage set, string memory value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);

            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /// @dev Removes a value from a set.
    ///      Returns `true` if the value was present and so, successfully removed from the set.
    function _remove(Set storage set, string memory value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;

                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /// @dev Returns whether `value` is in the set.
    function _contains(Set storage set, string memory value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /// @dev Returns the number of elements in the set.
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /// @dev Returns the element stored at position `index` in the set.
    ///      Note: the ordering of elements is not guaranteed to be fixed. It is unsafe to rely on
    ///      or compute based on the index of set elements.
    function _at(Set storage set, uint256 index) private view returns (string memory) {
        return set._values[index];
    }

    /// @dev Returns the values stored in the set.
    function _values(Set storage set) private view returns (string[] memory) {
        return set._values;
    }

    /// @dev Add `value` to the set.
    function add(Set storage set, string memory value) internal returns (bool) {
        return _add(set, value);
    }

    /// @dev Remove `value` from the set.
    function remove(Set storage set, string memory value) internal returns (bool) {
        return _remove(set, value);
    }

    /// @dev Returns whether `value` is in the set.
    function contains(Set storage set, string memory value) internal view returns (bool) {
        return _contains(set, value);
    }

    /// @dev Returns the number of elements in the set.
    function length(Set storage set) internal view returns (uint256) {
        return _length(set);
    }

    /// @dev Returns the element stored at position `index` in the set.
    function at(Set storage set, uint256 index) internal view returns (string memory) {
        return _at(set, index);
    }

    /// @dev Returns the values stored in the set.
    function values(Set storage set) internal view returns (string[] memory) {
        return _values(set);
    }
}
