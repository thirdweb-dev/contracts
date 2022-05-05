// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../feature/interface/ITokenBundle.sol";

/**
 *  Thirdweb's Multiwrap contract lets you wrap arbitrary ERC20, ERC721 and ERC1155
 *  tokens you own into a single wrapped token / NFT.
 *
 *  A wrapped NFT can be unwrapped i.e. burned in exchange for its underlying contents.
 */

interface ITempMultiwrap is ITokenBundle {
    /// @notice The type of assets that can be wrapped.
    // enum TokenType {
    //     ERC20,
    //     ERC721,
    //     ERC1155
    // }

    /**
     *  @notice A generic interface to describe a token to wrap.
     *
     *  @param assetContract The contract address of the asset to wrap.
     *  @param tokenType     The token type (ERC20 / ERC721 / ERC1155) of the asset to wrap.
     *  @param tokenId       The token Id of the asset to wrap, if the asset is an ERC721 / ERC1155 NFT.
     *  @param amount        The amount of the asset to wrap, if the asset is an ERC20 / ERC1155 fungible token.
     */
    // struct Token {
    //     address assetContract;
    //     TokenType tokenType;
    //     uint256 tokenId;
    //     uint256 amount;
    // }

    /**
     *  @notice An internal data structure to track the wrapped contents of a wrapped NFT.
     *
     *  @param count The total kinds of assets i.e. `Token` wrapped.
     *  @param token Mapping from a UID -> to the asset i.e. `Token` at that UID.
     */
    // struct WrappedContents {
    //     uint256 count;
    //     mapping(uint256 => Token) token;
    // }

    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        address indexed recipientOfWrappedToken,
        uint256 indexed tokenIdOfWrappedToken,
        Token[] wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed unwrapper,
        address indexed recipientOfWrappedContents,
        uint256 indexed tokenIdOfWrappedToken,
        Token[] wrappedContents
    );

    /// @dev Emitted when the contract owner is updated.
    event OwnerUpdated(address prevOwner, address newOwner);

    /**
     *  @notice Wrap multiple ERC1155, ERC721, ERC20 tokens into a single wrapped NFT.
     *
     *  @param wrappedContents    The tokens to wrap.
     *  @param uriForWrappedToken The metadata URI for the wrapped NFT.
     *  @param recipient          The recipient of the wrapped NFT.
     */
    function wrap(
        Token[] memory wrappedContents,
        string calldata uriForWrappedToken,
        address recipient
    ) external payable returns (uint256 tokenId);

    /**
     *  @notice Unwrap a wrapped NFT to retrieve underlying ERC1155, ERC721, ERC20 tokens.
     *
     *  @param tokenId   The token Id of the wrapped NFT to unwrap.
     *  @param recipient The recipient of the underlying ERC1155, ERC721, ERC20 tokens of the wrapped NFT.
     */
    function unwrap(uint256 tokenId, address recipient) external;
}
