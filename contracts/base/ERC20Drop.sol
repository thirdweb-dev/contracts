// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-presets/token/ERC20/extensions/ERC20Permit.sol";

import "../extension/ContractMetadata.sol";
import "../extension/Multicall.sol";
import "../extension/Ownable.sol";
import "../extension/PrimarySale.sol";
import { SignatureMintERC20 } from "../extension/SignatureMintERC20.sol";
import "../extension/DropSinglePhase.sol";

import "../lib/CurrencyTransferLib.sol";

/**
 *      BASE:      ERC20
 *      EXTENSION: SignatureMintERC20, DropSinglePhase
 *
 *  The `ERC20Drop` contract uses the `ERC20Base` contract, along with the `SignatureMintERC20` and `DropSinglePhase` extensions.
 *
 *  The 'signature minting' mechanism in the `SignatureMintERC20` extension is a way for a contract admin to authorize
 *  an external party's request to mint tokens on the admin's contract. At a high level, this means you can authorize
 *  some external party to mint tokens on your contract, and specify what exactly will be minted by that external party.
 *
 *  The `drop` mechanism in the `DropSinglePhase` extension is a distribution mechanism for tokens. It lets
 *  you set restrictions such as a price to charge, an allowlist etc. when an address atttempts to mint tokens.
 *
 */

contract ERC20Drop is
    ContractMetadata,
    Multicall,
    Ownable,
    ERC20Permit,
    PrimarySale,
    SignatureMintERC20,
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
    ) ERC20Permit(_name, _symbol) {
        _setupContractURI(_contractURI);
        _setupOwner(msg.sender);
        _setupPrimarySaleRecipient(_primarySaleRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                        Signature minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice           Mints tokens according to the provided mint request.
     *
     *  @param _req       The payload / mint request.
     *  @param _signature The signature produced by an account signing the mint request.
     */
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        virtual
        returns (address signer)
    {
        require(_req.quantity > 0, "Minting zero tokens.");

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        /**
         *  Get receiver of tokens.
         *
         *  Note: If `_req.to == address(0)`, a `mintWithSignature` transaction sitting in the
         *        mempool can be frontrun by copying the input data, since the minted tokens
         *        will be sent to the `_msgSender()` in this case.
         */
        address receiver = _req.to == address(0) ? msg.sender : _req.to;

        // Collect price
        collectPriceOnClaim(_req.primarySaleRecipient, _req.quantity, _req.currency, _req.pricePerToken);

        // Mint tokens.
        _mint(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, _req);
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

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _canSignMintRequest(address _signer) internal view virtual override returns (bool) {
        return _signer == owner();
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
