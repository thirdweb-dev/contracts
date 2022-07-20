// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20SignatureMintVote.sol";

import "../extension/DropSinglePhase.sol";

/**
 *      BASE:      ERC20Vote
 *      EXTENSION: SignatureMintERC20, DropSinglePhase
 *
 *  The `ERC20Drop` contract uses the `ERC20Vote` contract, along with the `SignatureMintERC20` and `DropSinglePhase` extensions.
 *
 *  The 'signature minting' mechanism in the `SignatureMintERC20` extension is a way for a contract admin to authorize
 *  an external party's request to mint tokens on the admin's contract. At a high level, this means you can authorize
 *  some external party to mint tokens on your contract, and specify what exactly will be minted by that external party.
 *
 *  The `drop` mechanism in the `DropSinglePhase` extension is a distribution mechanism tokens. It lets
 *  you set restrictions such as a price to charge, an allowlist etc. when an address atttempts to mint tokens.
 *
 */

contract ERC20DropVote is ERC20SignatureMintVote, DropSinglePhase {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _contractURI,
        address _primarySaleRecipient
    ) ERC20SignatureMintVote(_name, _symbol, _decimals, _contractURI, _primarySaleRecipient) {}

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPriceOnClaim(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override(DropSinglePhase, ERC20SignatureMintVote) {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = (_quantityToClaim * _pricePerToken) / 1 ether;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == totalPrice, "Must send total price.");
        }

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, primarySaleRecipient(), totalPrice);
    }

    /// @dev Transfers the tokens being claimed.
    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed) internal override returns (uint256) {
        _mint(_to, _quantityBeingClaimed);
        return 0;
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return msg.sender == owner();
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function mint(address, uint256) public virtual override {
        revert("Not implemented.");
    }
}
