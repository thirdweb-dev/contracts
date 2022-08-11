// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC1155LazyMint.sol";
import "../extension/DelayedReveal.sol";

contract ERC1155DelayedReveal is ERC1155LazyMint, DelayedReveal {
    using TWStrings for uint256;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC1155LazyMint(_name, _symbol, _royaltyRecipient, _royaltyBps) {}

    /*//////////////////////////////////////////////////////////////
                        Overriden Metadata logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        (uint256 batchId, ) = getBatchId(_tokenId);
        string memory batchUri = getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Lazy minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The placeholder base URI for the 'n' number of NFTs being lazy minted, where the
     *                           metadata for each of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _encryptedBaseURI The encrypted base URI for the batch of NFTs being lazy minted.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _encryptedBaseURI
    ) public virtual override returns (uint256 batchId) {
        if (_encryptedBaseURI.length != 0) {
            _setEncryptedBaseURI(nextTokenIdToLazyMint + _amount, _encryptedBaseURI);
        }

        return super.lazyMint(_amount, _baseURIForTokens, _encryptedBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                        Delayed reveal logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice       Lets an authorized address reveal a batch of delayed reveal NFTs.
     *
     *  @param _index The ID for the batch of delayed-reveal NFTs to reveal.
     *  @param _key   The key with which the base URI for the relevant batch of NFTs was encrypted.
     */
    function reveal(uint256 _index, bytes calldata _key) external virtual override returns (string memory revealedURI) {
        require(_canReveal(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedBaseURI(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /// @dev Checks whether NFTs can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        return msg.sender == owner();
    }
}
