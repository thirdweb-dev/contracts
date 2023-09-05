// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant REENTRANCY_GUARD_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("reentrancy.guard.storage")) - 1));

    struct Data {
        uint256 _status;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _reentrancyGuardStorage()._status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_reentrancyGuardStorage()._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorage()._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorage()._status = _NOT_ENTERED;
    }

    /// @dev Returns the ReentrancyGuard storage.
    function _reentrancyGuardStorage() internal pure returns (ReentrancyGuardStorage.Data storage data) {
        data = ReentrancyGuardStorage.data();
    }
}
