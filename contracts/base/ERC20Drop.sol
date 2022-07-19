// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20SignatureMint.sol";

import "../extension/DropSinglePhase.sol";

contract ERC20Drop is 
    ERC20SignatureMint,
    DropSinglePhase
{
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _primarySaleRecipient
    ) ERC20SignatureMint(_name, _symbol, _contractURI, _primarySaleRecipient)
    {}

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPriceOnClaim(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override(DropSinglePhase, ERC20SignatureMint) {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "Must send total price.");
        }

        CurrencyTransferLib.transferCurrency(
            _currency,
            msg.sender,
            primarySaleRecipient(),
            totalPrice
        );
    }

    /// @dev Transfers the tokens being claimed.
    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        override
        returns (uint256)
    {
        _mint(_to, _quantityBeingClaimed);
        return 0;
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return msg.sender == owner();
    }
}