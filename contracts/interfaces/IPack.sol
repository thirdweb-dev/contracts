// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebOwnable.sol";
import "./IThirdwebRoyalty.sol";

interface IPack is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {

    /// @notice The types of tokens that can be added to packs.
    enum TokenType { ERC20, ERC721, ERC1155 }

    /**
     *  @notice A unit of content i.e. a token in a pack.
     *
     *  @param assetContract            The contract address of the token.
     *  @param tokenType                The type of the token -- ERC20 / ERC721 / ERC1155
     *  @param tokenId                  The tokenId of the the token, if applicable.
     *  @param totalAmountPacked        The total amount of this token packed in the pack.
     *  @param amountDistributedPerOpen The amount of this token to distribute as a unit,
     *                                  on opening a pack.
     */
    struct PackContent {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmountPacked;
        uint256 amountDistributedPerOpen;
    }

    /**
     *  @notice All info relevant to packs.
     *  
     *  @param contents The tokens packed in the packs.
     *  @param openStartTimestamp The timestamp after which packs can be opened.
     *  @param packUri The metadata URI for packs.
     *  @param totalCirculatingSupply The total amount of unopened packs.
     */
    struct PackInfo {
        PackContent[] contents;
        uint256 openStartTimestamp;
        string packUri;
        uint256 totalCirculatingSupply;
    }

    /**
     *  @notice Creates a pack with the stated contents.
     *
     *  @param contents The contents of the packs to be created.
     *  @param packUri The (metadata) URI assigned to the packs created.
     *  @param openStartTimestamp The timestamp after which packs can be opened.
     */
    function createPack(
        PackContent[] calldata contents,
        string calldata packUri,
        uint128 openStartTimestamp
    ) external;

    /**
     *  @notice Lets a pack owner open a pack and receive the pack's NFTs.
     *
     *  @param packId The identifier of the pack to open.
     *  @param amountToOpen The number of packs to open at once.
     */
    function openPack(uint256 packId, uint256 amountToOpen) external;
}
