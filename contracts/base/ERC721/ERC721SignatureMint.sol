// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721Base.sol";

import "../../feature/PrimarySale.sol";
import "../../feature/PermissionsEnumerable.sol";
import "../../feature/SignatureMintERC721.sol";

import "../../lib/CurrencyTransferLib.sol";

contract ERC721SignatureMint is 
    ERC721Base,
    PrimarySale,
    PermissionsEnumerable,
    SignatureMintERC721
{
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _contractURI,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC721Base(
            _name,
            _symbol,
            contractURI,
            _royaltyRecipient,
            _royaltyBps
        ) 
    {}

    /*//////////////////////////////////////////////////////////////
                        Signature minting logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer)
    {
        require(_req.quantity > 0, "Minting zero tokens.");

        uint256 tokenIdToMint = _nextTokenIdToMint();

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
        collectPriceOnClaim(_req.quantity, _req.currency, _req.pricePerToken);

        // Mint tokens.
        _safeMint(receiver, _req.quantity);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
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

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual {
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
}
