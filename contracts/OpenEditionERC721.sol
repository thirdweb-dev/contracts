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

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "./eip/ERC721AVirtualApproveUpgradeable.sol";

//  ==========  Internal imports    ==========

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "./extension/Multicall.sol";
import "./extension/ContractMetadata.sol";
import "./extension/PlatformFee.sol";
import "./extension/Royalty.sol";
import "./extension/PrimarySale.sol";
import "./extension/Ownable.sol";
import "./extension/SharedMetadata.sol";
import "./extension/PermissionsEnumerable.sol";
import "./extension/Drop.sol";

// OpenSea operator filter
import "./extension/DefaultOperatorFiltererUpgradeable.sol";

contract OpenEditionERC721 is
    Initializable,
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    SharedMetadata,
    PermissionsEnumerable,
    Drop,
    ERC2771ContextUpgradeable,
    Multicall,
    DefaultOperatorFiltererUpgradeable,
    ERC721AUpgradeable
{
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private transferRole;
    /// @dev Only MINTER_ROLE holders can update the shared metadata of tokens.
    bytes32 private minterRole;

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external initializer {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC721A_init(_name, _symbol);
        __DefaultOperatorFilterer_init();

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);
        _setOperatorRestriction(true);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
        minterRole = _minterRole;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert("OpenCollectionERC721: URI query for nonexistent token.");
        }

        return _getURIFromSharedMetadata(_tokenId);
    }

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev The start token ID for the contract.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "!V");

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 fees;
        address feeRecipient;

        PlatformFeeType feeType = getPlatformFeeType();
        if (feeType == PlatformFeeType.Flat) {
            (feeRecipient, fees) = getFlatPlatformFeeInfo();
        } else {
            uint16 platformFeeBps;
            (feeRecipient, platformFeeBps) = getPlatformFeeInfo();
            fees = (totalPrice * platformFeeBps) / MAX_BPS;
        }

        require(totalPrice >= fees, "!F");

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), feeRecipient, fees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - fees);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal override returns (uint256 startTokenId) {
        startTokenId = _currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _isDefaultAdmin() internal view virtual override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return _currentIndex;
    }

    /// @dev The next token ID of the NFT that can be claimed.
    function nextTokenIdToClaim() external view returns (uint256) {
        return _currentIndex;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) external virtual {
        // note: ERC721AUpgradeable's `_burn(uint256,bool)` internally checks for token approvals.
        _burn(tokenId, true);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(transferRole, from) && !hasRole(transferRole, to)) {
                revert("!Transfer-Role");
            }
        }
    }

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
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
