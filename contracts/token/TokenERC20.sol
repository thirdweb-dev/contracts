// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//Interface
import { ITokenERC20 } from "../interfaces/token/ITokenERC20.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

// Security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

// Meta transactions
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "../openzeppelin-presets/utils/MulticallUpgradeable.sol";

contract TokenERC20 is
    ITokenERC20,
    Initializable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    ERC20VotesUpgradeable,
    AccessControlEnumerableUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("TokenERC20");
    uint256 private constant VERSION = 1;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 internal constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Whether transfers on tokens are restricted.
    bool public isTransferRestricted;

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    string public contractURI;

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin role");
        _;
    }

    /// @dev Emitted when restrictions on transfers is updated.
    event RestrictedTransferUpdated(bool transferable);

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _deployer,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder
    ) external initializer {
        __TokenERC20_init(_deployer, _name, _symbol, _trustedForwarder, _contractURI);
    }

    function __TokenERC20_init(
        address _deployer,
        string memory _name,
        string memory _symbol,
        address _trustedForwarder,
        string memory _uri
    ) internal onlyInitializing {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init_unchained(_trustedForwarder);
        __ERC20Permit_init(_name);
        __ERC20_init_unchained(_name, _symbol);

        __TokenERC20_init_unchained(_deployer, _uri);
    }

    function __TokenERC20_init_unchained(address _deployer, string memory _uri) internal onlyInitializing {
        // Initialize this contract's state.
        contractURI = _uri;

        _setupRole(DEFAULT_ADMIN_ROLE, _deployer);
        _setupRole(TRANSFER_ROLE, _deployer);
        _setupRole(MINTER_ROLE, _deployer);
        _setupRole(PAUSER_ROLE, _deployer);
    }

    /// @dev Returns the module type of the contract.
    function moduleType() external pure virtual returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function version() external pure virtual returns (uint8) {
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
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);

        if (isTransferRestricted && from != address(0) && to != address(0)) {
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
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "not pauser.");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "not pauser.");
        _unpause();
    }

    /// @dev Lets a protocol admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        isTransferRestricted = _restrictedTransfer;

        emit RestrictedTransferUpdated(_restrictedTransfer);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyModuleAdmin {
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
