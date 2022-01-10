// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { MulticallUpgradeable } from "./openzeppelin-presets/utils/MulticallUpgradeable.sol";
import { AccessControlEnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Upgradeability
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DataStore is
    Initializable,
    ContextUpgradeable,
    MulticallUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable 
{
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    string private contractURI;

    mapping(uint256 => uint256) private _data;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(address _trustedForwarder, string memory _uri) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __Context_init();
        __Multicall_init();
        __ERC2771Context_init(_trustedForwarder);
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();

        // Initialize this contract's state.
        contractURI = _uri;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EDITOR_ROLE, _msgSender());
    }

    /// @dev Sets retrictions on upgrades.
    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
    }

    function getUint(uint256 _key) external view returns (uint256 value) {
        value = _data[_key];
    }

    function setUint(uint256 _key, uint256 _value) external onlyRole(EDITOR_ROLE) {
        _data[_key] = _value;
    }

    /// @dev See ERC2771
    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See ERC2771
    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyModuleAdmin {
        contractURI = _URI;
    }
}
