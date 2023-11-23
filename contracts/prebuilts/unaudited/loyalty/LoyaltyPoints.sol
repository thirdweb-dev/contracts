// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

// Interface
import "../../interface/ILoyaltyPoints.sol";

// Base
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// Lib
import "../../../lib/CurrencyTransferLib.sol";

// Extensions
import "../../../extension/SignatureMintERC20Upgradeable.sol";
import "../../../extension/ContractMetadata.sol";
import "../../../extension/PrimarySale.sol";
import "../../../extension/PlatformFee.sol";
import "../../../extension/PermissionsEnumerable.sol";
import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 *  @title LoyaltyPoints
 *
 *  @custom:description This contract is a loyalty points contract. Each token represents a loyalty point. Loyalty points can
 *                      be cancelled (i.e. 'burned') by its owner or an approved operator. Loyalty points can be revoked
 *                      (i.e. 'burned') without its owner's approval, by an admin of the contract.
 */

contract LoyaltyPoints is
    ILoyaltyPoints,
    ContractMetadata,
    PrimarySale,
    PlatformFee,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    SignatureMintERC20Upgradeable,
    ERC20Upgradeable
{
    /*///////////////////////////////////////////////////////////////
                                State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only REVOKE_ROLE holders can revoke a loyalty card.
    bytes32 private constant REVOKE_ROLE = keccak256("REVOKE_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Mapping from token owner => total tokens minted to them in the contract's lifetime.
    mapping(address => uint256) private _mintedToInLifetime;

    /*///////////////////////////////////////////////////////////////
                        Constructor + initializer
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC20_init_unchained(_name, _symbol);
        __SignatureMintERC20_init(_name);
        __ReentrancyGuard_init();

        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);

        _setupRole(REVOKE_ROLE, _defaultAdmin);
        _setRoleAdmin(REVOKE_ROLE, REVOKE_ROLE);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the total tokens minted to `owner` in the contract's lifetime.
    function getTotalMintedInLifetime(address _owner) external view returns (uint256) {
        return _mintedToInLifetime[_owner];
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints tokens to a recipient using a signature from an authorized party.
    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable nonReentrant returns (address signer) {
        signer = _processRequest(_req, _signature);
        address receiver = _req.to;

        _collectPriceOnClaim(_req.primarySaleRecipient, _req.currency, _req.price);
        _mintTo(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, _req);
    }

    /// @notice Mints `amount` of tokens to the recipient `to`.
    function mintTo(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _mintTo(to, amount);
    }

    /// @notice Burns `amount` of tokens. See {ERC20-_burn}.
    function cancel(address _owner, uint256 _amount) external virtual {
        address caller = _msgSender();
        if (caller != _owner) {
            _spendAllowance(_owner, caller, _amount);
        }
        _burn(_owner, _amount);
    }

    /// @notice Burns `amount` of tokens from `owner`'s balance (without requiring approval from owner). See {ERC20-_burn}.
    function revoke(address _owner, uint256 _amount) external virtual onlyRole(REVOKE_ROLE) {
        _burn(_owner, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Mints `amount` of tokens to `to`
    function _mintTo(address _to, uint256 _amount) internal {
        _mint(_to, _amount);
        emit TokensMinted(_to, _amount);
    }

    /// @dev Collects and distributes the primary sale value of tokens being minted.
    function _collectPriceOnClaim(address _primarySaleRecipient, address _currency, uint256 _price) internal {
        if (_price == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == _price;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 fees;
        address feeRecipient;

        PlatformFeeType feeType = getPlatformFeeType();
        if (feeType == PlatformFeeType.Flat) {
            (feeRecipient, fees) = getFlatPlatformFeeInfo();
        } else {
            uint16 platformFeeBps;
            (feeRecipient, platformFeeBps) = getPlatformFeeInfo();
            fees = (_price * platformFeeBps) / MAX_BPS;
        }

        require(_price >= fees, "!F");

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), feeRecipient, fees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, _price - fees);
    }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "transfers restricted.");
        }

        if (from == address(0)) {
            _mintedToInLifetime[to] += amount;
        }
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(MINTER_ROLE, _signer);
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
