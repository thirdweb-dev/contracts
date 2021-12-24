// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  `SignatureMint` is an ERC 721 contract. It lets anyone mint NFTs by producing a mint request
 *  and a signature (produced by an account with MINTER_ROLE, signing the mint request).
 */
interface ISignatureMint721 {
    
    /**
     *  @notice The body of a request to mint NFTs.
     *
     *  @param to The receiver of the NFTs to mint.
     *  @param baseURI The base URI to assign to the NFTs to mint.
     *  @param amountToMint The amount of NFTs to mint.
     *  @param pricePerToken The price per NFT to mint.
     *  @param currency The currency in which the price per token must be paid.
     *  @param validityStartTimestamp The unix timestamp after which the request is valid.
     *  @param validityEndTimestamp The unix timestamp after which the request expires.
     *  @param uid A unique identifier for the request.
     */
    struct MintRequest {
        address to;
        string baseURI;
        uint256 amountToMint;
        uint256 pricePerToken;
        address currency;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes uid;
    }

    /// @dev Emitted when tokens are minted.
    event TokensMinted(MintRequest mintRequest, bytes signature, address indexed requestor);

    /// @dev Emitted when a new sale recipient is set.
    event NewSaleRecipient(address indexed recipient);

    /// @dev Emitted when the royalty fee bps is updated
    event RoyaltyUpdated(uint256 newRoyaltyBps);

    /// @dev Emitted when fee on primary sales is updated.
    event PrimarySalesFeeUpdates(uint256 newFeeBps);

    /// @dev Emitted when transfers are set as restricted / not-restricted.
    event TransfersRestricted(bool restricted);

    /**
     *  @notice Verifies that a mint request is signed by an account holding
     *         MINTER_ROLE (at the time of the function call).
     *
     *  @param req The mint request.
     *  @param signature The signature produced by an account signing the mint request.
     */
    function verify(MintRequest calldata req, bytes calldata signature) external view returns (bool);

    /**
     *  @notice Mints an NFT according to the provided mint request.
     *
     *  @param req The mint request.
     *  @param signature he signature produced by an account signing the mint request.
     */
    function mint(MintRequest calldata req, bytes calldata signature) external payable;
}