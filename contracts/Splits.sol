// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import { PaymentSplitterUpgradeable } from "./openzeppelin-presets/finance/PaymentSplitterUpgradeable.sol";

// Meta-tx
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Access
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

// Utils
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MulticallUpgradeable } from "./openzeppelin-presets/utils/MulticallUpgradeable.sol";

// Upgradeability
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Splits is
    Initializable,
    MulticallUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable,
    PaymentSplitterUpgradeable
{
    /// @dev Contract level metadata.
    string public contractURI;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    constructor() initializer {}

    /// @dev Performs the job of the constructor.
    /// @dev shares_ are scaled by 10,000 to prevent precision loss when including fees
    function initialize(
        string memory _contractURI,
        address _trustedForwarder,        
        address[] memory payees,
        uint256[] memory shares_
    ) external initializer {
        // Initialize inherited contracts: most base -> most derived
        __Multicall_init();
        __ERC2771Context_init(_trustedForwarder);
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        __PaymentSplitter_init();

        require(payees.length == shares_.length, "unequal number of payees and shares provided.");
        require(payees.length > 0, "no payees provided.");

        // Set contract metadata
        contractURI = _contractURI;

        // Scaling the share, so we don't lose precision on division
        for (uint256 i = 0; i < payees.length; i++) {
            // WARNING: Do not call _addPayee outside of this initializer
            _addPayee(payees[i], shares_[i] * 10000);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Sets retrictions on upgrades.
    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
    }

    /// @dev See ERC2771
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See ERC2771
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
        contractURI = _uri;
    }
}
