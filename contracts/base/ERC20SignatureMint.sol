// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./ERC20Base.sol";

import "../extension/PrimarySale.sol";
import { SignatureMintERC20 } from "../extension/SignatureMintERC20.sol";
import { ReentrancyGuard } from "../extension/upgradeable/ReentrancyGuard.sol";
import { CurrencyTransferLib } from "../lib/CurrencyTransferLib.sol";

/**
 *      BASE:      ERC20
 *      EXTENSION: SignatureMintERC20
 *
 *  The `ERC20SignatureMint` contract uses the `ERC20Base` contract, along with the `SignatureMintERC20` extension.
 *
 *  The 'signature minting' mechanism in the `SignatureMintERC20` extension uses EIP 712, and is a way for a contract
 *  admin to authorize an external party's request to mint tokens on the admin's contract. At a high level, this means
 *  you can authorize some external party to mint tokens on your contract, and specify what exactly will be minted by
 *  that external party.
 *
 */

contract ERC20SignatureMint is ERC20Base, PrimarySale, SignatureMintERC20, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _primarySaleRecipient
    ) ERC20Base(_defaultAdmin, _name, _symbol) {
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
    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable virtual nonReentrant returns (address signer) {
        require(_req.quantity > 0, "Minting zero tokens.");

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        // Collect price
        _collectPriceOnClaim(_req.primarySaleRecipient, _req.currency, _req.price);

        // Mint tokens.
        _mint(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, _req);
    }

    /*//////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _canSignMintRequest(address _signer) internal view virtual override returns (bool) {
        return _signer == owner();
    }

    /// @dev Returns whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function _collectPriceOnClaim(address _primarySaleRecipient, address _currency, uint256 _price) internal virtual {
        if (_price == 0) {
            require(msg.value == 0, "!Value");
            return;
        }

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            require(msg.value == _price, "Must send total price.");
        } else {
            require(msg.value == 0, "msg value not zero");
        }

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, saleRecipient, _price);
    }
}
