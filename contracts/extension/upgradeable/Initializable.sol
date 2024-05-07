// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../../lib/Address.sol";

library InitStorage {
    /// @custom:storage-location erc7201:init.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("init.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant INIT_STORAGE_POSITION = 0x322cf19c484104d3b1a9c2982ebae869ede3fa5f6c4703ca41b9a48c76ee0300;

    /// @dev Layout of the entrypoint contract's storage.
    struct Data {
        uint8 initialized;
        bool initializing;
    }

    /// @dev Returns the entrypoint contract's data at the relevant storage location.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = INIT_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract Initializable {
    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initStorage().initialized = 1;
        if (isTopLevelCall) {
            _initStorage().initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initStorage().initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initStorage().initialized = version;
        _initStorage().initializing = true;
        _;
        _initStorage().initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initStorage().initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initStorage().initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /// @dev Returns the InitStorage storage.
    function _initStorage() internal pure returns (InitStorage.Data storage data) {
        data = InitStorage.data();
    }
}
