// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import "./openzeppelin-presets/finance/PaymentSplitter.sol";

import { Registry } from "./Registry.sol";
import { ProtocolControl } from "./ProtocolControl.sol";

// Meta transactions
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Security
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * Royalty automatically adds protocol provider (the registry) of protocol control to the payees
 * and shares that represent the fees.
 */
contract Royalty is Initializable, PaymentSplitter, AccessControlEnumerable, ERC2771ContextUpgradeable, Multicall {
    /// @dev The protocol control center.
    ProtocolControl private controlCenter;

    /// @dev Contract level metadata.
    string private _contractURI;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    /// @dev shares_ are scaled by 10,000 to prevent precision loss when including fees
    constructor() initializer {}

    /// @dev Performs the job of the constructor.
    function initialize (
        address payable _controlCenter,
        address _trustedForwarder,
        string memory _uri,
        address[] memory payees,
        uint256[] memory shares_
    )
        external
        initializer
    {
        // Initialize ERC2771 Context
        __ERC2771Context_init(_trustedForwarder);

        require(payees.length == shares_.length, "Royalty: unequal number of payees and shares provided.");
        require(payees.length > 0, "Royalty: no payees provided.");

        // Set contract metadata
        _contractURI = _uri;
        // Set the protocol's control center.
        controlCenter = ProtocolControl(_controlCenter);

        // Scaling the share, so we don't lose precision on division
        for (uint256 i = 0; i < payees.length; i++) {
            // WARNING: Do not call _addPayee outside of this constructor.
            _addPayee(payees[i], shares_[i] * 10000);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC2771
    function _msgSender() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See ERC2771
    function _msgData() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyModuleAdmin {
        _contractURI = _URI;
    }

    /// @dev Returns the URI for the contract-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
