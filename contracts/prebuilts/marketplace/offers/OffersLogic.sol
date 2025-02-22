// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "./OffersStorage.sol";

// ====== External imports ======
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../../eip/interface/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// ====== Internal imports ======

import "../../../extension/interface/IPlatformFee.sol";
import "../../../extension/upgradeable/ERC2771ContextConsumer.sol";
import "../../../extension/upgradeable/ReentrancyGuard.sol";
import "../../../extension/upgradeable/PermissionsEnumerable.sol";
import { RoyaltyPaymentsLogic } from "../../../extension/upgradeable/RoyaltyPayments.sol";
import { CurrencyTransferLib } from "../../../lib/CurrencyTransferLib.sol";

/**
 * @author  thirdweb.com
 */
contract OffersLogic is IOffers, ReentrancyGuard, ERC2771ContextConsumer {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/
    /// @dev Can create offer for only assets from NFT contracts with asset role, when offers are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 private constant MAX_BPS = 10_000;

    address public constant DEFAULT_FEE_RECIPIENT = 0x1Af20C6B23373350aD464700B5965CE4B0D2aD94;
    uint16 private constant DEFAULT_FEE_BPS = 100;

    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyAssetRole(address _asset) {
        require(Permissions(address(this)).hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
    }

    /// @dev Checks whether caller is a offer creator.
    modifier onlyOfferor(uint256 _offerId) {
        require(_offersStorage().offers[_offerId].offeror == _msgSender(), "!Offeror");
        _;
    }

    /// @dev Checks whether an auction exists.
    modifier onlyExistingOffer(uint256 _offerId) {
        require(_offersStorage().offers[_offerId].status == IOffers.Status.CREATED, "Marketplace: invalid offer.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    function makeOffer(
        OfferParams memory _params
    ) external onlyAssetRole(_params.assetContract) returns (uint256 _offerId) {
        _offerId = _getNextOfferId();
        address _offeror = _msgSender();
        TokenType _tokenType = _getTokenType(_params.assetContract);

        _validateNewOffer(_params, _tokenType);

        Offer memory _offer = Offer({
            offerId: _offerId,
            offeror: _offeror,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            tokenType: _tokenType,
            quantity: _params.quantity,
            currency: _params.currency,
            totalPrice: _params.totalPrice,
            expirationTimestamp: _params.expirationTimestamp,
            status: IOffers.Status.CREATED
        });

        _offersStorage().offers[_offerId] = _offer;

        emit NewOffer(_offeror, _offerId, _params.assetContract, _offer);
    }

    function cancelOffer(uint256 _offerId) external onlyExistingOffer(_offerId) onlyOfferor(_offerId) {
        _offersStorage().offers[_offerId].status = IOffers.Status.CANCELLED;

        emit CancelledOffer(_msgSender(), _offerId);
    }

    function acceptOffer(uint256 _offerId) external nonReentrant onlyExistingOffer(_offerId) {
        Offer memory _targetOffer = _offersStorage().offers[_offerId];

        require(_targetOffer.expirationTimestamp > block.timestamp, "EXPIRED");

        require(
            _validateERC20BalAndAllowance(_targetOffer.offeror, _targetOffer.currency, _targetOffer.totalPrice),
            "Marketplace: insufficient currency balance."
        );

        _validateOwnershipAndApproval(
            _msgSender(),
            _targetOffer.assetContract,
            _targetOffer.tokenId,
            _targetOffer.quantity,
            _targetOffer.tokenType
        );

        _offersStorage().offers[_offerId].status = IOffers.Status.COMPLETED;

        _payout(_targetOffer.offeror, _msgSender(), _targetOffer.currency, _targetOffer.totalPrice, _targetOffer);
        _transferOfferTokens(_msgSender(), _targetOffer.offeror, _targetOffer.quantity, _targetOffer);

        emit AcceptedOffer(
            _targetOffer.offeror,
            _targetOffer.offerId,
            _targetOffer.assetContract,
            _targetOffer.tokenId,
            _msgSender(),
            _targetOffer.quantity,
            _targetOffer.totalPrice
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns total number of offers
    function totalOffers() public view returns (uint256) {
        return _offersStorage().totalOffers;
    }

    /// @dev Returns existing offer with the given uid.
    function getOffer(uint256 _offerId) external view returns (Offer memory _offer) {
        _offer = _offersStorage().offers[_offerId];
    }

    /// @dev Returns all existing offers within the specified range.
    function getAllOffers(uint256 _startId, uint256 _endId) external view returns (Offer[] memory _allOffers) {
        require(_startId <= _endId && _endId < _offersStorage().totalOffers, "invalid range");

        _allOffers = new Offer[](_endId - _startId + 1);

        for (uint256 i = _startId; i <= _endId; i += 1) {
            _allOffers[i - _startId] = _offersStorage().offers[i];
        }
    }

    /// @dev Returns offers within the specified range, where offeror has sufficient balance.
    function getAllValidOffers(uint256 _startId, uint256 _endId) external view returns (Offer[] memory _validOffers) {
        require(_startId <= _endId && _endId < _offersStorage().totalOffers, "invalid range");

        Offer[] memory _offers = new Offer[](_endId - _startId + 1);
        uint256 _offerCount;

        for (uint256 i = _startId; i <= _endId; i += 1) {
            uint256 j = i - _startId;
            _offers[j] = _offersStorage().offers[i];
            if (_validateExistingOffer(_offers[j])) {
                _offerCount += 1;
            }
        }

        _validOffers = new Offer[](_offerCount);
        uint256 index = 0;
        uint256 count = _offers.length;
        for (uint256 i = 0; i < count; i += 1) {
            if (_validateExistingOffer(_offers[i])) {
                _validOffers[index++] = _offers[i];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next offer Id.
    function _getNextOfferId() internal returns (uint256 id) {
        id = _offersStorage().totalOffers;
        _offersStorage().totalOffers += 1;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("Marketplace: token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Checks whether the auction creator owns and has approved marketplace to transfer auctioned tokens.
    function _validateNewOffer(OfferParams memory _params, TokenType _tokenType) internal view {
        require(_params.totalPrice > 0, "zero price.");
        require(_params.quantity > 0, "Marketplace: wanted zero tokens.");
        require(_params.quantity == 1 || _tokenType == TokenType.ERC1155, "Marketplace: wanted invalid quantity.");
        require(
            _params.expirationTimestamp + 60 minutes > block.timestamp,
            "Marketplace: invalid expiration timestamp."
        );

        require(
            _validateERC20BalAndAllowance(_msgSender(), _params.currency, _params.totalPrice),
            "Marketplace: insufficient currency balance."
        );
    }

    /// @dev Checks whether the offer exists, is active, and if the offeror has sufficient balance.
    function _validateExistingOffer(Offer memory _targetOffer) internal view returns (bool isValid) {
        isValid =
            _targetOffer.expirationTimestamp > block.timestamp &&
            _targetOffer.status == IOffers.Status.CREATED &&
            _validateERC20BalAndAllowance(_targetOffer.offeror, _targetOffer.currency, _targetOffer.totalPrice);
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Marketplace to transfer NFTs.
    function _validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view {
        address market = address(this);
        bool isValid;

        if (_tokenType == TokenType.ERC1155) {
            isValid =
                IERC1155(_assetContract).balanceOf(_tokenOwner, _tokenId) >= _quantity &&
                IERC1155(_assetContract).isApprovedForAll(_tokenOwner, market);
        } else if (_tokenType == TokenType.ERC721) {
            isValid =
                IERC721(_assetContract).ownerOf(_tokenId) == _tokenOwner &&
                (IERC721(_assetContract).getApproved(_tokenId) == market ||
                    IERC721(_assetContract).isApprovedForAll(_tokenOwner, market));
        }

        require(isValid, "Marketplace: not owner or approved tokens.");
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Markeplace to transfer the appropriate amount of currency
    function _validateERC20BalAndAllowance(
        address _tokenOwner,
        address _currency,
        uint256 _amount
    ) internal view returns (bool isValid) {
        isValid =
            IERC20(_currency).balanceOf(_tokenOwner) >= _amount &&
            IERC20(_currency).allowance(_tokenOwner, address(this)) >= _amount;
    }

    /// @dev Transfers tokens.
    function _transferOfferTokens(address _from, address _to, uint256 _quantity, Offer memory _offer) internal {
        if (_offer.tokenType == TokenType.ERC1155) {
            IERC1155(_offer.assetContract).safeTransferFrom(_from, _to, _offer.tokenId, _quantity, "");
        } else if (_offer.tokenType == TokenType.ERC721) {
            IERC721(_offer.assetContract).safeTransferFrom(_from, _to, _offer.tokenId, "");
        }
    }

    /// @dev Pays out stakeholders in a sale.
    function _payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Offer memory _offer
    ) internal {
        uint256 amountRemaining;

        // Payout platform fee
        {
            uint256 platformFeesTw = (_totalPayoutAmount * DEFAULT_FEE_BPS) / MAX_BPS;
            (address platformFeeRecipient, uint16 platformFeeBps) = IPlatformFee(address(this)).getPlatformFeeInfo();
            uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

            // Transfer platform fee
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _currencyToUse,
                _payer,
                DEFAULT_FEE_RECIPIENT,
                platformFeesTw,
                address(0)
            );
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _currencyToUse,
                _payer,
                platformFeeRecipient,
                platformFeeCut,
                address(0)
            );

            amountRemaining = _totalPayoutAmount - platformFeeCut - platformFeesTw;
        }

        // Payout royalties
        {
            // Get royalty recipients and amounts
            (address payable[] memory recipients, uint256[] memory amounts) = RoyaltyPaymentsLogic(address(this))
                .getRoyalty(_offer.assetContract, _offer.tokenId, _totalPayoutAmount);

            uint256 royaltyRecipientCount = recipients.length;

            if (royaltyRecipientCount != 0) {
                uint256 royaltyCut;
                address royaltyRecipient;

                for (uint256 i = 0; i < royaltyRecipientCount; ) {
                    royaltyRecipient = recipients[i];
                    royaltyCut = amounts[i];

                    // Check payout amount remaining is enough to cover royalty payment
                    require(amountRemaining >= royaltyCut, "fees exceed the price");

                    // Transfer royalty
                    CurrencyTransferLib.transferCurrencyWithWrapper(
                        _currencyToUse,
                        _payer,
                        royaltyRecipient,
                        royaltyCut,
                        address(0)
                    );

                    unchecked {
                        amountRemaining -= royaltyCut;
                        ++i;
                    }
                }
            }
        }

        // Distribute price to token owner
        CurrencyTransferLib.transferCurrencyWithWrapper(_currencyToUse, _payer, _payee, amountRemaining, address(0));
    }

    /// @dev Returns the Offers storage.
    function _offersStorage() internal pure returns (OffersStorage.Data storage data) {
        data = OffersStorage.data();
    }
}
