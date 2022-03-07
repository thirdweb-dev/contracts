// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebRoyalty.sol";
import "./IThirdwebOwnable.sol";
import "../lib/MultiTokenTransferLib.sol";

interface IMultiwrap is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {
    /// @dev Emitted when tokens are wrapped.
    event TokensWrapped(
        address indexed wrapper,
        uint256 indexed tokenIdOfShares,
        MultiTokenTransferLib.MultiToken wrappedContents
    );

    /// @dev Emitted when tokens are unwrapped.
    event TokensUnwrapped(
        address indexed wrapper,
        address sentTo,
        uint256 indexed tokenIdOfShares,
        uint256 sharesUnwrapped,
        MultiTokenTransferLib.MultiToken wrappedContents
    );

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);

    /**
     *  @notice Wrap multiple ERC1155, ERC721, ERC20 tokens into 'n' shares (i.e. variable supply of 1 ERC 1155 token)
     *
     *  @param wrappedContents The tokens to wrap.
     *  @param shares The number of shares to issue for the wrapped contents.
     *  @param uriForShares The URI for the shares i.e. wrapped token.
     */
    function wrap(
        MultiTokenTransferLib.MultiToken calldata wrappedContents,
        uint256 shares,
        string calldata uriForShares
    ) external payable returns (uint256 tokenId);

    /**
     *  @notice Unwrap shares to retrieve underlying ERC1155, ERC721, ERC20 tokens.
     *
     *  @param tokenId The token Id of the tokens to unwrap.
     *  @param amountToRedeem The amount of shares to unwrap
     */
    function unwrap(
        uint256 tokenId,
        uint256 amountToRedeem,
        address _sendTo
    ) external;
}
