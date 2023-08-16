// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../extension/interface/ITokenBundle.sol";

/**
 *  Thirdweb's Multiwrap contract lets you wrap arbitrary ERC20, ERC721 and ERC1155
 *  tokens you own into a single wrapped token / NFT.
 *
 *  A wrapped NFT can be unwrapped i.e. burned in exchange for its underlying contents.
 */

interface IMultiwrap is ITokenBundle {
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
        uint256 indexed tokenIdOfWrappedToken
    );

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
