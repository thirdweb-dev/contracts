// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC721Wrapper {
    /// @dev Emitted when token is wrapped.
    event TokenWrapped(
        address indexed wrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken
    );

    /// @dev Emitted when token is unwrapped.
    event TokenUnwrapped(
        address indexed unwrapper,
        address indexed recipient,
        uint256 indexed tokenIdOfWrappedToken
    );

    /**
     *  @notice Wrap an ERC721 token.
     *
     *  @param recipient   The recipient of the wrapped NFT.
     *  @param tokenId     ID of token being wrapped.
     */
    function wrap(
        address recipient,
        uint256 tokenId
    ) external;

    /**
     *  @notice Unwrap a token to retrieve the underlying ERC721 token.
     *
     *  @param recipient The recipient of the underlying NFT.
     *  @param tokenId   The token Id of the wrapped NFT to unwrap.
     */
    function unwrap(address recipient, uint256 tokenId) external;
}
