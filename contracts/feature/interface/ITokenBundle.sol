// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Group together arbitrary ERC20, ERC721 and ERC1155 tokens into a single bundle.
 *
 *  This bundle of tokens is a generic list of tokens that can have multiple use cases,
 *  such as mapping to an NFT, or put in an escrow, etc.
 */

interface ITokenBundle {
    /// @notice The type of assets that can be wrapped.
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     *  @notice A generic interface to describe a token to be put in a bundle.
     *
     *  @param assetContract The contract address of the asset to bind.
     *  @param tokenType     The token type (ERC20 / ERC721 / ERC1155) of the asset to bind.
     *  @param tokenId       The token Id of the asset to bind, if the asset is an ERC721 / ERC1155 NFT.
     *  @param totalAmount   The amount of the asset to bind, if the asset is an ERC20 / ERC1155 fungible token.
     */
    struct Token {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmount;
    }

    /**
     *  @notice An internal data structure to track the contents of a bundle.
     *
     *  @param count    The total kinds of assets i.e. `Token` inside a bundle.
     *  @param uri      The (metadata) URI assigned to the bundle created
     *  @param tokens   Mapping from a UID -> to the asset i.e. `Token` at that UID.
     */
    struct BundleInfo {
        uint256 count;
        string uri;
        mapping(uint256 => Token) tokens;
    }
}
