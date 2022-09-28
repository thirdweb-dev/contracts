// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import { IDirectListings } from "./IMarketplace.sol";

// ====== External imports ======
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ====== Internal imports ======

import "../extension/PermissionsEnumerable.sol";

contract DirectListings is IDirectListings, Context, PermissionsEnumerable {
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only lister role holders can create listings, when listings are restricted by lister address.
    bytes32 private constant LISTER_ROLE = keccak256("LISTER_ROLE");
    /// @dev Only assets from NFT contracts with asset role can be listed, when listings are restricted by asset address.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    uint256 private totalListings;

    mapping(uint256 => Listing) private listings;
    mapping(uint256 => mapping(address => bool)) private isBuyerApprovedForListing;
    mapping(uint256 => mapping(address => bool)) private isCurrencyApprovedForListing;
    mapping(uint256 => mapping(address => uint256)) private currencyPriceForListing;

    /*///////////////////////////////////////////////////////////////
                            Modifier
    //////////////////////////////////////////////////////////////*/

    modifier onlyListerRole() {
        require(hasRoleWithSwitch(LISTER_ROLE, _msgSender()), "!LISTER_ROLE");
        _;
    }

    modifier onlyAssetRole(address _asset) {
        require(hasRoleWithSwitch(ASSET_ROLE, _asset), "!ASSET_ROLE");
        _;
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

        listings[listingId] = listing;

        emit NewListing(listingCreator, listingId, listing);
    }

    /// @notice Update an existing listing of your ERC721 or ERC1155 NFTs.
    function updateListing(uint256 _listingId, ListingParameters memory _params)
        external
        onlyAssetRole(_params.assetContract)
    {
        address listingCreator = _msgSender();

        Listing memory listing = listings[_listingId];
        require(listing.listingCreator == listingCreator, "Not listing creator.");

        TokenType tokenType = _getTokenType(_params.assetContract);

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

        listings[_listingId] = listing;

        emit UpdatedListing(listingCreator, _listingId, listing);
    }

    /// @notice Cancel an existing listing of your ERC721 or ERC1155 NFTs.
    function cancelListing(uint256 _listingId) external {
        address listingCreator = _msgSender();

        Listing memory listing = listings[_listingId];
        require(listing.listingCreator == listingCreator, "Not listing creator.");

        delete listings[_listingId];

        emit CancelledListing(listingCreator, _listingId);
    }

    /// @notice Approve or disapprove a buyer for a reserved listing.
    function approveBuyerForLisitng(
        uint256 _listingId,
        address _buyer,
        bool _toApprove
    ) external {
        address listingCreator = _msgSender();

        Listing memory listing = listings[_listingId];
        require(listing.listingCreator == listingCreator, "Not listing creator.");

        isBuyerApprovedForListing[_listingId][_buyer] = _toApprove;

        emit ApprovalForListing(_listingId, _buyer, _toApprove);
    }

    /// @notice Approve a currency and its associated price per token, for a listing.
    function approveCurrencyForLisitng(
        uint256 _listingId,
        address _currency,
        uint256 _pricePerTokenInCurrency,
        bool _toApprove
    ) external {
        address listingCreator = _msgSender();

        Listing memory listing = listings[_listingId];
        require(listing.listingCreator == listingCreator, "Not listing creator.");

        require(_currency != listing.currency, "Re-approving main listing currency.");

        isCurrencyApprovedForListing[_listingId][_currency] = _toApprove;
        currencyPriceForListing[_listingId][_currency] = _pricePerTokenInCurrency;

        emit CurrencyPriceForListing(_listingId, _currency, _pricePerTokenInCurrency, _toApprove);
    }

    /// @notice Buy from a listing of ERC721 or ERC1155 NFTs.
    function buyFromListing(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _totalPrice
    ) external payable {
        Listing memory listing = listings[_listingId];
        require(listing.assetContract != address(0), "Listing DNE");

        require(_quantity > 0 && _quantity <= listing.quantity, "Buying invalid quantity");

        _validateOwnershipAndApproval(
            listing.listingCreator,
            listing.assetContract,
            listing.tokenId,
            _quantity,
            listing.tokenType
        );

        address targetCurrency;
        uint256 targetTotalPrice;

        if (isCurrencyApprovedForListing[_listingId][_currency]) {
            targetCurrency = _currency;
            targetTotalPrice = _quantity * currencyPriceForListing[_listingId][_currency];
        } else {
            targetCurrency = listing.currency;
            targetTotalPrice = _quantity * listing.pricePerToken;
        }

        require(targetTotalPrice == _totalPrice, "Unexpected total price");

        address buyer = _msgSender();
        _validateERC20BalAndAllowance(buyer, targetCurrency, targetTotalPrice);

        listings[_listingId] -= _quantity;

        _executeSale();
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all non-cancelled listings.
    function getAllListings() external view returns (Listing[] memory allListings) {
        uint256 total = totalListings;
        uint256 nonEmptyListings;

        for (uint256 i = 0; i < total; i += 1) {
            if (listings[i].listingCreator != address(0)) {
                nonEmptyListings += 1;
            }
        }

        uint256[] memory ids = new uint256[](nonEmptyListings);
        uint256 idxForIds;
        for (uint256 i = 0; i < nonEmptyListings; i += 1) {
            if (listings[i].listingCreator != address(0)) {
                ids[idxForIds] = i;
                idxForIds += 1;
            }
        }

        allListings = new Listing[](nonEmptyListings);
        for (uint256 i = 0; i < ids.length; i += 1) {
            allListings[i] = listings[ids[i]];
        }
    }

    /// @notice Returns a listing at a particular listing ID.
    function getListing(uint256 _listingId) external view returns (Listing memory listing) {
        listing = listings[_listingId];
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the next listing Id.
    function _getNextListingId() internal returns (uint256 id) {
        id = totalListings;
        totalListings += 1;
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

        _validateOwnershipAndApproval(
            _msgSender(),
            _params.assetContract,
            _params.tokenId,
            _params.quantity,
            _tokenType
        );
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

        require(isValid, "!BALNFT");
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
}
