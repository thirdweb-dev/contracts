// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11; 

/**
 *  The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into
 *  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed
 *  on opening a pack depends on the relative supply of all tokens in the packs.
 */

interface IPack {

    /// @notice The types of tokens that can be added to packs.
    enum TokenType { ERC20, ERC721, ERC1155 }

    /**
     *  @notice A unit of content i.e. a token in a pack.
     *
     *  @param assetContract            The contract address of the token.
     *  @param tokenType                The type of the token -- ERC20 / ERC721 / ERC1155
     *  @param tokenId                  The tokenId of the the token, if applicable.
     *  @param totalAmountPacked        The total amount of this token packed in the pack.
     *  @param amountPerUnit            The amount of this token to distribute as a unit,
     *                                  on opening a pack.
     */
    struct PackContent {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmountPacked;
        uint256 amountPerUnit;
    }

    /**
     *  @notice All info relevant to packs.
     *  
     *  @param contents                 The reward units packed in the packs.
     *  @param openStartTimestamp       The timestamp after which packs can be opened.
     *  @param amountDistributedPerOpen The number of reward units distributed per open.
     *  @param totalCirculatingSupply   The total amount of unopened packs.
     *  @param packUri                  The metadata URI for packs.
     */
    struct PackInfo {
        PackContent[] contents;
        uint128 openStartTimestamp;
        uint128 amountDistributedPerOpen;
        uint256 totalCirculatingSupply;
        string uri;
    }

    /**
     *  @notice Creates a pack with the stated contents.
     *
     *  @param contents                 The reward units to pack in the packs.
     *  @param packUri                  The (metadata) URI assigned to the packs created.
     *  @param openStartTimestamp       The timestamp after which packs can be opened.
     *  @param amountDistributedPerOpen The number of reward units distributed per open.
     */
    function createPack(
        PackContent[] calldata contents,
        string calldata packUri,
        uint128 openStartTimestamp,
        uint128 amountDistributedPerOpen
    ) external;

    /**
     *  @notice Lets a pack owner open a pack and receive the pack's reward unit.
     *
     *  @param packId       The identifier of the pack to open.
     *  @param amountToOpen The number of packs to open at once.
     */
    function openPack(uint256 packId, uint256 amountToOpen) external;
}
