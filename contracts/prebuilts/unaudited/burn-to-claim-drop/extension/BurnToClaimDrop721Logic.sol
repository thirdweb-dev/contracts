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

import { BurnToClaimDrop721Storage } from "./BurnToClaimDrop721Storage.sol";

import "../../../../lib/Strings.sol";
import "../../../../lib/CurrencyTransferLib.sol";

import { IERC2981 } from "../../../../eip/interface/IERC2981.sol";
import { Context, ERC721AUpgradeable, ERC721AStorage } from "../../../../eip/ERC721AUpgradeable.sol";

import { IERC2771Context } from "../../../../extension/interface/IERC2771Context.sol";

import { ERC2771ContextUpgradeable } from "../../../../extension/upgradeable/ERC2771ContextUpgradeable.sol";
import { DelayedReveal } from "../../../../extension/upgradeable/DelayedReveal.sol";
import { PrimarySale } from "../../../../extension/upgradeable/PrimarySale.sol";
import { PlatformFee } from "../../../../extension/upgradeable/PlatformFee.sol";
import { Royalty, IERC165 } from "../../../../extension/upgradeable/Royalty.sol";
import { LazyMint } from "../../../../extension/upgradeable/LazyMint.sol";
import { Drop } from "../../../../extension/upgradeable/Drop.sol";
import { ContractMetadata } from "../../../../extension/upgradeable/ContractMetadata.sol";
import { Ownable } from "../../../../extension/upgradeable/Ownable.sol";
import { PermissionsStorage } from "../../../../extension/upgradeable/Permissions.sol";
import { BurnToClaim, BurnToClaimStorage } from "../../../../extension/upgradeable/BurnToClaim.sol";
import { ReentrancyGuard } from "../../../../extension/upgradeable/ReentrancyGuard.sol";

contract BurnToClaimDrop721Logic is
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    BurnToClaim,
    DelayedReveal,
    LazyMint,
    Drop,
    ERC2771ContextUpgradeable,
    ERC721AUpgradeable,
    ReentrancyGuard
{
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max NFTs that can be minted is updated.
    event MaxTotalMintedUpdated(uint256 maxTotalMinted);

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the URI for a given tokenId.
     *  @dev The URI, for a given tokenId, is returned once it is lazy minted, even if it might not be actually minted. (See `LazyMint`)
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /// @notice See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981).interfaceId == interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting + delayed-reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256) {
        uint256 nextId = nextTokenIdToLazyMint();
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextId + _amount, _data);
            }
        }

        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @notice Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key) external returns (string memory revealedURI) {
        require(_hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim lazy minted tokens after burning required tokens from origin contract.
    function burnAndClaim(uint256 _burnTokenId, uint256 _quantity) external payable nonReentrant {
        _checkTokenSupply(_quantity);

        // Verify and burn tokens on origin contract
        address _tokenOwner = _dropMsgSender();
        verifyBurnToClaim(_tokenOwner, _burnTokenId, _quantity);
        _burnTokensOnOrigin(_tokenOwner, _burnTokenId, _quantity);

        // Collect price
        _collectPriceOnClaim(
            address(0),
            _quantity,
            _burnToClaimStorage().burnToClaimInfo.currency,
            _burnToClaimStorage().burnToClaimInfo.mintPriceForNewToken
        );

        // Mint tokens.
        _safeMint(_tokenOwner, _quantity);

        // emit event
        emit TokensBurnedAndClaimed(
            _burnToClaimStorage().burnToClaimInfo.originContractAddress,
            _tokenOwner,
            _burnTokenId,
            _quantity
        );
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Lets a contract admin set the global maximum NFTs that can be minted.
    function setMaxTotalMinted(uint256 _maxTotalMinted) external {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin.");

        BurnToClaimDrop721Storage.Data storage data = BurnToClaimDrop721Storage.burnToClaimDrop721Storage();
        data.maxTotalMinted = _maxTotalMinted;
        emit MaxTotalMintedUpdated(_maxTotalMinted);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Check if given quantity is available for minting.
    function _checkTokenSupply(uint256 _quantity) internal view {
        uint256 _maxTotalMinted = maxTotalMinted();
        uint256 currentTotalMinted = totalMinted();

        require(currentTotalMinted + _quantity <= nextTokenIdToLazyMint(), "!Tokens");
        require(
            _maxTotalMinted == 0 || currentTotalMinted + _quantity <= _maxTotalMinted,
            "exceed max total mint cap."
        );
    }

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        _checkTokenSupply(_quantity);
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "Invalid msg value");

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - platformFees);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal override returns (uint256 startTokenId) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        startTokenId = data._currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return _hasRole(MINTER_ROLE, _msgSender());
    }

    /// @dev Returns whether burn-to-claim info can be set in the given execution context.
    function _canSetBurnToClaim() internal view virtual override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        unchecked {
            return data._currentIndex - _startTokenId();
        }
    }

    /// @notice The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint();
    }

    /// @notice The next token ID of the NFT that can be claimed.
    function nextTokenIdToClaim() external view returns (uint256) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        return data._currentIndex;
    }

    /// @notice Global max total NFTs that can be minted.
    function maxTotalMinted() public view returns (uint256) {
        BurnToClaimDrop721Storage.Data storage data = BurnToClaimDrop721Storage.burnToClaimDrop721Storage();
        return data.maxTotalMinted;
    }

    /// @notice Burns `tokenId`. See {ERC721-_burn}.
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
        if (!_hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!_hasRole(TRANSFER_ROLE, from) && !_hasRole(TRANSFER_ROLE, to)) {
                revert("!Transfer-Role");
            }
        }
    }

    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[role][addr];
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (address) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
