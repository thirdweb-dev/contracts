// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC1155Wrapper {
    /// @dev Emitted when token is wrapped.
    event TokenWrapped(
        address indexed wrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken,
        uint256 amount
    );

    /// @dev Emitted when token is unwrapped.
    event TokenUnwrapped(
        address indexed unwrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken,
        uint256 amount
    );

    /**
     *  @notice Wrap ERC1155 tokens.
     *
     *  @param recipient   The recipient of the wrapped tokens.
     *  @param tokenId     ID of tokens being wrapped.
     *  @param amount      amount of tokens being wrapped.
     */
    function wrap(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     *  @notice Unwrap a token to retrieve the underlying ERC1155 token.
     *
     *  @param recipient The recipient of the underlying tokens
     *  @param tokenId   ID of the wrapped tokens to unwrap.
     *  @param amount    amount of tokens being wrapped.
     */
    function unwrap(
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) external;
}
