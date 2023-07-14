// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

/**
 * @author  thirdweb.com
 */
library InitStorage {
    /// @dev The location of the storage of the entrypoint contract's data.
    uint256 constant INIT_STORAGE_POSITION =  44548265482661845010179032359748061925569542820020140819497684272150058605280;

    /// @dev Layout of the entrypoint contract's storage.
    struct Data {
        bool initialized;
    }

    /// @dev Returns the entrypoint contract's data at the relevant storage location.
    function initStorage() internal pure returns (Data storage initData) {
        bytes32 position = bytes32(INIT_STORAGE_POSITION);
        assembly {
            initData.slot := position
        }
    }
}
