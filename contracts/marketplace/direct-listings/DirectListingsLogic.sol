// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./DirectListingsStorage.sol";

// ====== External imports ======
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// ====== Internal imports ======

import "../extension/ERC2771ContextConsumer.sol";

import "../../extension/interface/IPlatformFee.sol";

import "../extension/ReentrancyGuard.sol";
import "../extension/PermissionsEnumerable.sol";
import { CurrencyTransferLib } from "../../lib/CurrencyTransferLib.sol";

contract DirectListings is IDirectListings, ReentrancyGuard, ERC2771ContextConsumer {
    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /*///////////////////////////////////////////////////////////////
                            Modifier
    //////////////////////////////////////////////////////////////*/

    modifier onlyListerRole() {
        require(PermissionsEnumerable(address(this)).hasRoleWithSwitch(LISTER_ROLE, _msgSender()), "!LISTER_ROLE");
        _;
    }

    modifier onlyAssetRole(address _asset) {
        require(PermissionsEnumerable(address(this)).hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
    }

    /// @dev Checks whether caller is a listing creator.
    modifier onlyListingCreator(uint256 _listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();
        require(data.listings[_listingId].listingCreator == _msgSender(), "!Creator");
        _;
    }

    /// @dev Checks whether a listing exists.
    modifier onlyExistingListing(uint256 _listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();
        require(data.listings[_listingId].assetContract != address(0), "DNE");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper) {
        nativeTokenWrapper = _nativeTokenWrapper;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice List ERC721 or ERC1155 NFTs for sale at a fixed price.
    function createListing(ListingParameters calldata _params)
        external
        onlyListerRole
        onlyAssetRole(_params.assetContract)
        returns (uint256 listingId)
    {
        listingId = _getNextListingId();
        address listingCreator = _msgSender();
        TokenType tokenType = _getTokenType(_params.assetContract);

        require(
            _params.startTimestamp >= block.timestamp && _params.startTimestamp < _params.endTimestamp,
            "invalid timestamps."
        );

        _validateNewListing(_params, tokenType);

        Listing memory listing = Listing({
            listingId: listingId,
            listingCreator: listingCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            pricePerToken: _params.pricePerToken,
            startTimestamp: _params.startTimestamp,
            endTimestamp: _params.endTimestamp,
            reserved: _params.reserved,
            tokenType: tokenType
        });

        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        data.listings[listingId] = listing;

        emit NewListing(listingCreator, listingId, listing);
    }

    /// @notice Update an existing listing of your ERC721 or ERC1155 NFTs.
    function updateListing(uint256 _listingId, ListingParameters memory _params)
        external
        onlyAssetRole(_params.assetContract)
        onlyListingCreator(_listingId)
    {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        address listingCreator = _msgSender();
        Listing memory listing = data.listings[_listingId];
        TokenType tokenType = _getTokenType(_params.assetContract);

        require(
            _params.startTimestamp >= listing.startTimestamp && _params.startTimestamp < _params.endTimestamp,
            "invalid timestamps."
        );

        _validateNewListing(_params, tokenType);

        listing = Listing({
            listingId: _listingId,
            listingCreator: listingCreator,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantity,
            currency: _params.currency,
            pricePerToken: _params.pricePerToken,
            startTimestamp: _params.startTimestamp,
            endTimestamp: _params.endTimestamp,
            reserved: _params.reserved,
            tokenType: tokenType
        });

        data.listings[_listingId] = listing;

        emit UpdatedListing(listingCreator, _listingId, listing);
    }

    /// @notice Cancel an existing listing of your ERC721 or ERC1155 NFTs.
    function cancelListing(uint256 _listingId) external onlyExistingListing(_listingId) onlyListingCreator(_listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        delete data.listings[_listingId];
        emit CancelledListing(_msgSender(), _listingId);
    }

    /// @notice Approve or disapprove a buyer for a reserved listing.
    function approveBuyerForListing(
        uint256 _listingId,
        address _buyer,
        bool _toApprove
    ) external onlyListingCreator(_listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        require(data.listings[_listingId].reserved, "not reserved listing");

        data.isBuyerApprovedForListing[_listingId][_buyer] = _toApprove;

        emit ApprovalForListing(_listingId, _buyer, _toApprove);
    }

    /// @notice Approve a currency and its associated price per token, for a listing.
    function approveCurrencyForListing(
        uint256 _listingId,
        address _currency,
        uint256 _pricePerTokenInCurrency,
        bool _toApprove
    ) external onlyListingCreator(_listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        Listing memory listing = data.listings[_listingId];
        require(_currency != listing.currency, "Re-approving main listing currency.");

        data.isCurrencyApprovedForListing[_listingId][_currency] = _toApprove;
        data.currencyPriceForListing[_listingId][_currency] = _pricePerTokenInCurrency;

        emit CurrencyPriceForListing(_listingId, _currency, _pricePerTokenInCurrency, _toApprove);
    }

    /// @notice Buy from a listing of ERC721 or ERC1155 NFTs.
    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _expectedTotalPrice
    ) external payable nonReentrant onlyExistingListing(_listingId) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        Listing memory listing = data.listings[_listingId];
        address buyer = _msgSender();

        require(!listing.reserved || data.isBuyerApprovedForListing[_listingId][buyer], "buyer not approved");
        require(_quantity > 0 && _quantity <= listing.quantity, "Buying invalid quantity");
        require(
            block.timestamp < listing.endTimestamp && block.timestamp >= listing.startTimestamp,
            "not within sale window."
        );

        require(
            _validateOwnershipAndApproval(
                listing.listingCreator,
                listing.assetContract,
                listing.tokenId,
                _quantity,
                listing.tokenType
            ),
            "!BALNFT"
        );

        address targetCurrency = _currency;
        uint256 targetTotalPrice;

        if (data.isCurrencyApprovedForListing[_listingId][targetCurrency]) {
            targetTotalPrice = _quantity * data.currencyPriceForListing[_listingId][targetCurrency];
        } else {
            require(targetCurrency == listing.currency, "Paying in invalid currency.");
            targetTotalPrice = _quantity * listing.pricePerToken;
        }

        require(targetTotalPrice == _expectedTotalPrice, "Unexpected total price");

        // Check: buyer owns and has approved sufficient currency for sale.
        if (targetCurrency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == targetTotalPrice, "msg.value != price");
        } else {
            _validateERC20BalAndAllowance(buyer, targetCurrency, targetTotalPrice);
        }

        if (listing.quantity == _quantity) {
            delete data.listings[_listingId];
        } else {
            data.listings[_listingId].quantity -= _quantity;
        }

        _payout(buyer, listing.listingCreator, targetCurrency, targetTotalPrice, listing);
        _transferListingTokens(listing.listingCreator, _buyFor, _quantity, listing);

        emit NewSale(
            listing.listingId,
            listing.assetContract,
            listing.listingCreator,
            buyer,
            _quantity,
            targetTotalPrice
        );
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the total number of listings ever created in the Marketplace.
    function totalListings() external view returns (uint256) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();
        return data.totalListings;
    }

    /// @notice Returns whether a buyer is approved for a listing.
    function isBuyerApprovedForListing(uint256 _listingId, address _buyer) external view returns (bool) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();
        return data.isBuyerApprovedForListing[_listingId][_buyer];
    }

    /// @notice Returns whether a currency is approved for a listing.
    function isCurrencyApprovedForListing(uint256 _listingId, address _currency) external view returns (bool) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();
        return data.isCurrencyApprovedForListing[_listingId][_currency];
    }

    /// @notice Returns the price per token for a listing, in the given currency.
    function currencyPriceForListing(uint256 _listingId, address _currency) external view returns (uint256) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        if (!data.isCurrencyApprovedForListing[_listingId][_currency]) {
            revert("Currency not approved for listing");
        }

        return data.currencyPriceForListing[_listingId][_currency];
    }

    /// @notice Returns all non-cancelled listings.
    function getAllListings(uint256 _startId, uint256 _endId) external view returns (Listing[] memory allListings) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        uint256 total = data.totalListings;
        uint256 nonEmptyListings;

        require(_startId < _endId && _endId < total, "invalid range");

        for (uint256 i = _startId; i <= _endId; i += 1) {
            if (data.listings[i].listingCreator != address(0)) {
                nonEmptyListings += 1;
            }
        }

        allListings = new Listing[](nonEmptyListings);
        for (uint256 i = 0; i < nonEmptyListings; i += 1) {
            if (data.listings[i].listingCreator != address(0)) {
                allListings[i] = data.listings[i];
            }
        }
    }

    /// @dev Returns listings within the specified range, where lister has sufficient balance.
    function getAllValidListings(uint256 _startId, uint256 _endId) external view returns (Listing[] memory _listings) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        require(_startId < _endId && _endId < data.totalListings, "invalid range");

        uint256 _listingCount;
        for (uint256 i = _startId; i <= _endId; i += 1) {
            if (_validateExistingListing(data.listings[i])) {
                _listingCount += 1;
            }
        }

        _listings = new Listing[](_listingCount);
        for (uint256 i = 0; i < _listingCount; i += 1) {
            if (_validateExistingListing(data.listings[i])) {
                _listings[i] = data.listings[i];
            }
        }
    }

    /// @notice Returns a listing at a particular listing ID.
    function getListing(uint256 _listingId)
        external
        view
        onlyExistingListing(_listingId)
        returns (Listing memory listing)
    {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        listing = data.listings[_listingId];
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next listing Id.
    function _getNextListingId() internal returns (uint256 id) {
        DirectListingsStorage.Data storage data = DirectListingsStorage.directListingsStorage();

        id = data.totalListings;
        data.totalListings += 1;
    }

    /// @dev Returns the interface supported by a contract.
    function _getTokenType(address _assetContract) internal view returns (TokenType tokenType) {
        if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
            tokenType = TokenType.ERC1155;
        } else if (IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)) {
            tokenType = TokenType.ERC721;
        } else {
            revert("token must be ERC1155 or ERC721.");
        }
    }

    /// @dev Checks whether the listing creator owns and has approved marketplace to transfer listed tokens.
    function _validateNewListing(ListingParameters memory _params, TokenType _tokenType) internal view {
        require(_params.quantity > 0, "Listing zero quantity.");
        require(_params.quantity == 1 || _tokenType == TokenType.ERC1155, "Listing invalid quantity.");

        require(
            _validateOwnershipAndApproval(
                _msgSender(),
                _params.assetContract,
                _params.tokenId,
                _params.quantity,
                _tokenType
            ),
            "!BALNFT"
        );
    }

    /// @dev Checks whether the listing exists, is active, and if the lister has sufficient balance.
    function _validateExistingListing(Listing memory _targetListing) internal view returns (bool isValid) {
        isValid =
            _targetListing.startTimestamp <= block.timestamp &&
            _targetListing.endTimestamp > block.timestamp &&
            _validateOwnershipAndApproval(
                _targetListing.listingCreator,
                _targetListing.assetContract,
                _targetListing.tokenId,
                _targetListing.quantity,
                _targetListing.tokenType
            );
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Marketplace to transfer NFTs.
    function _validateOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view returns (bool isValid) {
        address market = address(this);

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
    }

    /// @dev Validates that `_tokenOwner` owns and has approved Markeplace to transfer the appropriate amount of currency
    function _validateERC20BalAndAllowance(
        address _tokenOwner,
        address _currency,
        uint256 _amount
    ) internal view {
        require(
            IERC20(_currency).balanceOf(_tokenOwner) >= _amount &&
                IERC20(_currency).allowance(_tokenOwner, address(this)) >= _amount,
            "!BAL20"
        );
    }

    /// @dev Transfers tokens listed for sale in a direct or auction listing.
    function _transferListingTokens(
        address _from,
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, _quantity, "");
        } else if (_listing.tokenType == TokenType.ERC721) {
            IERC721(_listing.assetContract).safeTransferFrom(_from, _to, _listing.tokenId, "");
        }
    }

    /// @dev Pays out stakeholders in a sale.
    function _payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing
    ) internal {
        (address platformFeeRecipient, uint16 platformFeeBps) = IPlatformFee(address(this)).getPlatformFeeInfo();
        uint256 platformFeeCut = (_totalPayoutAmount * platformFeeBps) / MAX_BPS;

        uint256 royaltyCut;
        address royaltyRecipient;

        // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
        try IERC2981(_listing.assetContract).royaltyInfo(_listing.tokenId, _totalPayoutAmount) returns (
            address royaltyFeeRecipient,
            uint256 royaltyFeeAmount
        ) {
            if (royaltyFeeRecipient != address(0) && royaltyFeeAmount > 0) {
                require(royaltyFeeAmount + platformFeeCut <= _totalPayoutAmount, "fees exceed the price");
                royaltyRecipient = royaltyFeeRecipient;
                royaltyCut = royaltyFeeAmount;
            }
        } catch {}

        // Distribute price to token owner
        address _nativeTokenWrapper = nativeTokenWrapper;

        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            platformFeeRecipient,
            platformFeeCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            royaltyRecipient,
            royaltyCut,
            _nativeTokenWrapper
        );
        CurrencyTransferLib.transferCurrencyWithWrapper(
            _currencyToUse,
            _payer,
            _payee,
            _totalPayoutAmount - (platformFeeCut + royaltyCut),
            _nativeTokenWrapper
        );
    }
}
