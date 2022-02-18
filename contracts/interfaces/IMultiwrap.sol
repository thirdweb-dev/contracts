// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebRoyalty.sol";
import "./IThirdwebOwnable.sol";

interface IMultiwrap is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {
    struct WrappedContents {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
        address[] erc721AssetContracts;
        uint256[][] erc721TokensToWrap;
        address[] erc20AssetContracts;
        uint256[] erc20AmountsToWrap;
    }

    /// @dev Emitted when tokens are wrapped.
    event Wrapped(address indexed wrapper, uint256 indexed tokenIdOfShares, WrappedContents wrappedContents);

    /// @dev Emitted when tokens are unwrapped.
    event Unwrapped(
        address indexed wrapper,
        uint256 indexed tokenIdOfShares,
        uint256 sharesUnwrapped,
        WrappedContents wrappedContents
    );

    /// @dev Emitted when a new Owner is set.
    event NewOwner(address prevOwner, address newOwner);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyUpdated(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /**
     *  @notice Wrap multiple ERC1155, ERC721, ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
     *
     *  @param wrappedContents The tokens to wrap.
     *  @param shares The number of shares to issue for the wrapped contents.
     *  @param uriForShares The URI for the shares i.e. wrapped token.
     */
    function wrap(
        WrappedContents calldata wrappedContents,
        uint256 shares,
        string calldata uriForShares
    ) external payable;

    /**
     *  @notice Unwrap shares to retrieve underlying ERC1155, ERC721, ERC20 tokens.
     *
     *  @param tokenId The token Id of the tokens to unwrap.
     *  @param amountToRedeem The amount of shares to unwrap
     */
    function unwrap(uint256 tokenId, uint256 amountToRedeem) external;
}
