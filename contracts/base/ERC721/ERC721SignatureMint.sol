// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "./ERC721Base.sol";

import "../../feature/SignatureMintERC721.sol";
import "../../feature/Royalty.sol";

contract ERC721SignatureMint is 
    ERC721Base,
    Royalty,
    SignatureMintERC721
{
    constructor(
        string memory _name, 
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721Base(_name, _symbol) {
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
    }

    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer) 
    {
        require(_req.quantity == 1, "can mint exactly one");

        uint256 tokenIdToMint = nextTokenIdToMint;
        // require(tokenIdToMint + _req.quantity <= nextTokenIdToMint, "not enough minted tokens.");
        
        nextTokenIdToMint += 1;

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
        // collectPriceOnClaim(_req.quantity, _req.currency, _req.pricePerToken);

        // Mint tokens.
        _safeMint(receiver, tokenIdToMint, "");

        _setTokenURI(tokenIdToMint, _req.uri);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view virtual override returns (bool) {
        return _signer == owner;
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal override view returns (bool) {
        return msg.sender == owner;
    }
}