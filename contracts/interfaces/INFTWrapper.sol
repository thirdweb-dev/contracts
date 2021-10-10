// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INFTWrapper {
    /// @dev Wraps an ERC721 NFT as an ERC1155 NFT.
    function wrapERC721(
        uint256 startTokenId,
        address _tokenCreator,
        address[] calldata _nftContracts,
        uint256[] memory _tokenIds,
        string[] calldata _nftURIs
    )
        external
        returns (
            uint256[] memory tokenIds,
            uint256[] memory tokenAmountsToMint,
            uint256 endTokenId
        );

    /// @dev Wraps ERC20 tokens as ERC1155 NFTs.
    function wrapERC20(
        uint256 startTokenId,
        address _tokenCreator,
        address[] calldata _tokenContracts,
        uint256[] memory _tokenAmounts,
        uint256[] memory _numOfNftsToMint,
        string[] calldata _nftURIs
    ) external returns (uint256[] memory tokenIds, uint256 endTokenId);

    /// @dev Lets a wrapped nft owner redeem the underlying ERC721 NFT.
    function redeemERC721(uint256 _tokenId, address _redeemer) external;

    /// @dev Lets the nft owner redeem their ERC20 tokens.
    function redeemERC20(
        uint256 _tokenId,
        uint256 _amount,
        address _redeemer
    ) external;
}
