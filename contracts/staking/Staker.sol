// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//Interface
// import { ITokenERC20 } from "../interfaces/token/ITokenERC20.sol";

import "../interfaces/IThirdwebContract.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

// Security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Signature utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

// Meta transactions
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";

contract Staker is
    Initializable,
    IThirdwebContract,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20VotesUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    bytes32 private constant MODULE_TYPE = bytes32("Staker");
    uint256 private constant VERSION = 1;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    string public contractURI;

    /// @dev Max bps in the thirdweb system
    uint128 internal constant MAX_BPS = 10_000;

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_trustedForwarders);
        __ERC20Permit_init(_name);
        __ERC20_init_unchained(_name, _symbol);

        contractURI = _contractURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    /// @dev Returns the module type of the contract.
    function contractType() external pure virtual returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure virtual returns (uint8) {
        return uint8(VERSION);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mintTo(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _mintTo(to, amount);
    }

    /// @dev Mints `amount` of tokens to `to`
    function _mintTo(address _to, uint256 _amount) internal {
        _mint(_to, _amount);
        // emit TokensMinted(_to, _amount);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
