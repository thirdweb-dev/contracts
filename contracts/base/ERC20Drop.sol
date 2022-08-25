// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-presets/token/ERC20/extensions/ERC20Permit.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/PrimarySale.sol";
import "../extension/DropSinglePhase.sol";

import "../lib/CurrencyTransferLib.sol";

/**
 *      BASE:      ERC20
 *      EXTENSION: DropSinglePhase
 *
 *  The `ERC20Drop` smart contract implements the ERC20 standard.
 *  It includes the following additions to standard ERC20 logic:
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2612 compliance: See {ERC20-permit} method, which can be used to change an account's ERC20 allowance by
 *                             presenting a message signed by the account.
 *
 *  The `drop` mechanism in the `DropSinglePhase` extension is a distribution mechanism for tokens. It lets
 *  you set restrictions such as a price to charge, an allowlist etc. when an address atttempts to mint tokens.
 *
 */

contract ERC20Drop is ContractMetadata, Multicall, Ownable, ERC20Permit, PrimarySale, DropSinglePhase {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _primarySaleRecipient
    ) ERC20Permit(_name, _symbol) {
        _setupOwner(msg.sender);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an owner a given amount of their tokens.
     *  @dev             Caller should own the `_amount` of tokens.
     *
     *  @param _amount   The number of tokens to burn.
     */
    function burn(uint256 _amount) external virtual {
        require(balanceOf(msg.sender) >= _amount, "not enough balance");
        _burn(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = (_quantityToClaim * _pricePerToken) / 1 ether;
        require(totalPrice > 0, "quantity too low");

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "Must send total price.");
        }

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, saleRecipient, totalPrice);
    }

    /// @dev Transfers the tokens being claimed.
    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
        override
        returns (uint256)
    {
        _mint(_to, _quantityBeingClaimed);
        return 0;
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
