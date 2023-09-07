// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/Drop.sol";
import "../../extension/upgradeable/ERC2771ContextConsumer.sol";

import "../../lib/CurrencyTransferLib.sol";

import "../../extension/interface/IPermissions.sol";
import "../../extension/interface/IPlatformFee.sol";
import "../../extension/interface/IPrimarySale.sol";

import "./ERC721AMintExt.sol";
import "./LazyMintDelayedRevealExt.sol";

contract DropExt is Drop, ERC2771ContextConsumer {
    uint256 private constant MAX_BPS = 10000;

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        require(
            ERC721AMintExt(address(this)).currentIndex() + _quantity <=
                LazyMintDelayedRevealExt(address(this)).nextTokenIdToMint(),
            "!Tokens"
        );
        // require(maxTotalSupply == 0 || _currentIndex + _quantity <= maxTotalSupply, "!Supply");
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
        startTokenId = ERC721AMintExt(address(this)).currentIndex();
        ERC721AMintExt(address(this)).safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Determine what wallet can update claim conditions
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        // Check: default admin role
        try IPermissions(address(this)).hasRole(0x00, _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
