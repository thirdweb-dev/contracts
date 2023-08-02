// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Router
import "../smart-wallet/utils/BaseRouter.sol";

// Extensions
import "../marketplace/entrypoint/InitStorage.sol";
import "../dynamic-contracts/extension/ContractMetadata.sol";
import "../dynamic-contracts/extension/PermissionsEnumerable.sol";
import "../dynamic-contracts/extension/ReentrancyGuard.sol";

contract BaseMartRouter is BaseRouter, ContractMetadata, PermissionsEnumerable, ReentrancyGuard {
    /// @dev Initiliazes the contract, like a constructor.
    function initialize(address _defaultAdmin, address _targetNFTCollection) external {
        InitStorage.Data storage data = InitStorage.initStorage();

        require(!data.initialized, "Already initialized.");
        data.initialized = true;

        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(keccak256("LISTER_ROLE"), address(0));
        _setupRole(keccak256("ASSET_ROLE"), _targetNFTCollection);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension() internal view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
