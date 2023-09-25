// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

// Logic Extension
import "../inherit/internal/ERC721AInternal.sol";
import "../inherit/internal/LazyMintInternal.sol";
import "../inherit/internal/PermissionsInternal.sol";
import "../inherit/interface/ITokenIdTracker.sol";

import "../inherit/ERC2771ContextConsumer.sol";
import "../../extension/upgradeable/Drop.sol";
import "../../extension/upgradeable/Royalty.sol";
import "../../extension/upgradeable/PrimarySale.sol";
import "../../extension/upgradeable/PlatformFee.sol";

// Lib
import "../../lib/CurrencyTransferLib.sol";

library DropSupplyStorage {
    /// @custom:storage-location erc7201:drop.supply.storage
    bytes32 public constant DROP_SUPPLY_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("drop.supply.storage")) - 1));

    struct Data {
        uint256 maxMintSupply;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = DROP_SUPPLY_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract DropExt is Drop, ERC2771ContextConsumer, ERC721AInternal, PermissionsInternal, LazyMintInternal {
    uint256 private constant MAX_BPS = 10000;

    event MaxMintSupply(uint256 maxMintSupply);

    /// @notice Lets an authorized caller set max mint supply.
    function setMaxMintSupply(uint256 _maxMintSupply) external {
        require(_canSetClaimConditions(), "Not authorized.");
        DropSupplyStorage.data().maxMintSupply = _maxMintSupply;

        emit MaxMintSupply(_maxMintSupply);
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
        uint256 currentIndex = _currentIndex();

        require(ITokenIdTracker(address(this)).canMintQuantity(currentIndex, _quantity), "Not enough tokens");

        uint256 maxMintSupply = DropSupplyStorage.data().maxMintSupply;
        require(maxMintSupply == 0 || currentIndex + _quantity <= maxMintSupply, "!Supply");
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            require(msg.value == 0, "!V");
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = IPlatformFee(address(this)).getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0)
            ? IPrimarySale(address(this)).primarySaleRecipient()
            : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        bool validMsgValue;
        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            validMsgValue = msg.value == totalPrice;
        } else {
            validMsgValue = msg.value == 0;
        }
        require(validMsgValue, "!V");

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - platformFees);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        override
        returns (uint256 startTokenId)
    {
        startTokenId = _currentIndex();
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Determine what wallet can update claim conditions
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        // Check: default admin role
        return _hasRole(0x00, _msgSender());
    }
}
