// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @dev Edit: Make ERC-721 and ERC-1155 receiver.
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Token interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract NFTWrapper is ERC721Holder, ERC1155Holder {
    /// @dev The state of the underlying ERC 721 token, if any.
    struct ERC721Wrapped {
        address baseToken;
        address source;
        uint256 tokenId;
    }

    /// @dev The state of the underlying ERC 20 token, if any.
    struct ERC20Wrapped {
        address baseToken;
        address source;
        uint256 shares;
        uint256 underlyingTokenAmount;
    }

    /// @dev Emitted when ERC 721 wrapped as an ERC 1155 token is minted.
    event ERC721WrappedToken(
        address indexed baseToken,
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 721 token is redeemed.
    event ERC721Redeemed(
        address indexed baseToken,
        address indexed redeemer,
        address indexed sourceOfUnderlying,
        uint256 tokenIdOfUnderlying,
        uint256 tokenId
    );

    /// @dev Emitted when ERC 20 wrapped as an ERC 1155 token is minted.
    event ERC20WrappedToken(
        address indexed baseToken,
        address indexed creator,
        address indexed sourceOfUnderlying,
        uint256 totalAmountOfUnderlying,
        uint256 shares,
        uint256 tokenId,
        string tokenURI
    );

    /// @dev Emitted when an underlying ERC 20 token is redeemed.
    event ERC20Redeemed(
        address indexed baseToken,
        address indexed redeemer,
        address indexed sourceOfUnderlying,
        uint256 tokenId,
        uint256 tokenAmountReceived,
        uint256 sharesRedeemed
    );

    /// @dev NFT tokenId => state of underlying ERC721 token.
    mapping(address => mapping(uint256 => ERC721Wrapped)) public erc721WrappedTokens;

    /// @dev NFT tokenId => state of underlying ERC20 token.
    mapping(address => mapping(uint256 => ERC20Wrapped)) public erc20WrappedTokens;

    constructor() {}

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
        )
    {
        require(
            _nftContracts.length == _tokenIds.length && _nftContracts.length == _nftURIs.length,
            "NFTWrapper: Unequal number of configs provided."
        );

        address baseToken = msg.sender;

        bool isOwnerOfAll;
        bool isApprovedToTransferAll;

        // Get tokenId
        endTokenId = startTokenId;
        tokenIds = new uint256[](_nftContracts.length);
        tokenAmountsToMint = new uint256[](_nftContracts.length);

        for (uint256 i = 0; i < _nftContracts.length; i += 1) {
            // Check ownership
            isOwnerOfAll = IERC721(_nftContracts[i]).ownerOf(_tokenIds[i]) == _tokenCreator;
            // Check approval
            isApprovedToTransferAll =
                IERC721(_nftContracts[i]).getApproved(_tokenIds[i]) == address(this) ||
                IERC721(_nftContracts[i]).isApprovedForAll(_tokenCreator, address(this));

            // If owns NFT and approved to transfer.
            if (isOwnerOfAll && isApprovedToTransferAll) {
                // Transfer the NFT to this contract.
                IERC721(_nftContracts[i]).safeTransferFrom(_tokenCreator, address(this), _tokenIds[i]);

                // Map the native NFT tokenId to the underlying NFT
                erc721WrappedTokens[baseToken][endTokenId] = ERC721Wrapped({
                    baseToken: baseToken,
                    source: _nftContracts[i],
                    tokenId: _tokenIds[i]
                });

                // Update id
                tokenIds[i] = endTokenId;
                tokenAmountsToMint[i] = 1;
                endTokenId += 1;

                emit ERC721WrappedToken(baseToken, _tokenCreator, _nftContracts[i], _tokenIds[i], endTokenId, _nftURIs[i]);
            } else {
                break;
            }
        }

        require(isOwnerOfAll, "NFTWrapper: Only the owner of the NFT can wrap it.");
        require(isApprovedToTransferAll, "NFTWrapper: Must approve the contract to transfer the NFT.");
    }

    /// @dev Wraps ERC20 tokens as ERC1155 NFTs.
    function wrapERC20(
        uint256 startTokenId,
        address _tokenCreator,
        address[] calldata _tokenContracts,
        uint256[] memory _tokenAmounts,
        uint256[] memory _numOfNftsToMint,
        string[] calldata _nftURIs
    ) external returns (uint256[] memory tokenIds, uint256 endTokenId) {
        require(
            _tokenContracts.length == _tokenAmounts.length &&
                _tokenContracts.length == _numOfNftsToMint.length &&
                _tokenContracts.length == _nftURIs.length,
            "NFTWrapper: Unequal number of configs provided."
        );

        address baseToken = msg.sender;

        bool hasBalance;
        bool hasGivenAllowance;

        // Get tokenId
        endTokenId = startTokenId;
        tokenIds = new uint256[](_tokenContracts.length);

        for (uint256 i = 0; i < _tokenContracts.length; i += 1) {
            // Check balance
            hasBalance = IERC20(_tokenContracts[i]).balanceOf(_tokenCreator) >= _tokenAmounts[i];
            // Check allowance
            hasGivenAllowance = IERC20(_tokenContracts[i]).allowance(_tokenCreator, address(this)) >= _tokenAmounts[i];

            if (hasBalance && hasGivenAllowance) {
                require(
                    IERC20(_tokenContracts[i]).transferFrom(_tokenCreator, address(this), _tokenAmounts[i]),
                    "NFTWrapper: Failed to transfer ERC20 tokens."
                );

                // Store wrapped ERC20 token state.
                erc20WrappedTokens[baseToken][endTokenId] = ERC20Wrapped({
                    baseToken: baseToken,
                    source: _tokenContracts[i],
                    shares: _numOfNftsToMint[i],
                    underlyingTokenAmount: _tokenAmounts[i]
                });

                // Update id
                tokenIds[i] = endTokenId;
                endTokenId += 1;

                emit ERC20WrappedToken(
                    baseToken,
                    _tokenCreator,
                    _tokenContracts[i],
                    _tokenAmounts[i],
                    _numOfNftsToMint[i],
                    endTokenId,
                    _nftURIs[i]
                );
            } else {
                break;
            }
        }

        require(hasBalance, "NFTWrapper: Must own the amount of tokens being wrapped.");
        require(hasGivenAllowance, "NFTWrapper: Must approve this contract to transfer tokens.");
    }

    /// @dev Lets a wrapped nft owner redeem the underlying ERC721 NFT.
    function redeemERC721(uint256 _tokenId, address _redeemer) external {
        address baseToken = msg.sender;

        // Transfer the NFT to redeemer
        IERC721(erc721WrappedTokens[baseToken][_tokenId].source).safeTransferFrom(
            address(this),
            _redeemer,
            erc721WrappedTokens[baseToken][_tokenId].tokenId
        );

        emit ERC721Redeemed(
            baseToken,
            _redeemer,
            erc721WrappedTokens[baseToken][_tokenId].source,
            erc721WrappedTokens[baseToken][_tokenId].tokenId,
            _tokenId
        );
    }

    /// @dev Lets the nft owner redeem their ERC20 tokens.
    function redeemERC20(
        uint256 _tokenId,
        uint256 _amount,
        address _redeemer
    ) external {
        address baseToken = msg.sender;

        // Get the ERC20 token amount to distribute
        uint256 amountToDistribute = (erc20WrappedTokens[baseToken][_tokenId].underlyingTokenAmount * _amount) /
            erc20WrappedTokens[baseToken][_tokenId].shares;

        // Transfer the ERC20 tokens to redeemer
        require(
            IERC20(erc20WrappedTokens[baseToken][_tokenId].source).transfer(_redeemer, amountToDistribute),
            "NFTWrapper: Failed to transfer ERC20 tokens."
        );

        emit ERC20Redeemed(
            baseToken,
            _redeemer,            
            erc20WrappedTokens[baseToken][_tokenId].source,
            _tokenId,
            amountToDistribute,
            _amount
        );
    }
}
