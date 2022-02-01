// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Base
import "./openzeppelin-presets/finance/PaymentSplitterUpgradeable.sol";
import "./interfaces/IThirdwebModule.sol";

// Meta-tx
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Access
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

// Utils
import "./openzeppelin-presets/utils/MulticallUpgradeable.sol";

contract Splits is
    IThirdwebModule,
    Initializable,
    MulticallUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    PaymentSplitterUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Splits");
    uint256 private constant VERSION = 1;

    /// @dev Contract level metadata.
    string public contractURI;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    constructor(address _thirdwebFee) PaymentSplitterUpgradeable(_thirdwebFee) initializer {}

    /// @dev Performs the job of the constructor.
    /// @dev shares_ are scaled by 10,000 to prevent precision loss when including fees
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address _trustedForwarder,
        address[] memory payees,
        uint256[] memory shares_
    ) external initializer {
        // Initialize inherited contracts: most base -> most derived
        __ERC2771Context_init(_trustedForwarder);

        require(payees.length == shares_.length, "unequal number of payees and shares provided.");
        require(payees.length > 0, "no payees provided.");

        // Set contract metadata
        contractURI = _contractURI;

        // Scaling the share, so we don't lose precision on division
        for (uint256 i = 0; i < payees.length; i++) {
            // WARNING: Do not call _addPayee outside of this initializer
            _addPayee(payees[i], shares_[i] * 10000);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /// @dev Returns the module type of the contract.
    function moduleType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure returns (uint8) {
        return uint8(VERSION);
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
