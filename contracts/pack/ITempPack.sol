// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// import "../feature/interface/ITokenBundle.sol";

// /**
//  *  The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into
//  *  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed
//  *  on opening a pack depends on the relative supply of all tokens in the packs.
//  */

// interface ITempPack is ITokenBundle {

//     /// @notice The types of tokens that can be added to packs.
//     // enum TokenType { ERC20, ERC721, ERC1155 }

//     /**
//      *  @notice A unit of content i.e. a token in a pack.
//      *
//      *  @param assetContract            The contract address of the token.
//      *  @param tokenType                The type of the token -- ERC20 / ERC721 / ERC1155
//      *  @param tokenId                  The tokenId of the the token, if applicable.
//      *  @param totalAmountPacked        The total amount of this token packed in the pack.
//      *  @param amountPerUnit            The amount of this token to distribute as a unit,
//      *                                  on opening a pack.
//      */
//     // struct PackContent {
//     //     address assetContract;
//     //     TokenType tokenType;
//     //     uint256 tokenId;
//     //     uint256 totalAmountPacked;
//     //     uint256 amountPerUnit;
//     // }

//     /**
//      *  @notice All info relevant to packs.
//      *
//      *  @param contents                 The reward units packed in the packs.
//      *  @param openStartTimestamp       The timestamp after which packs can be opened.
//      *  @param amountDistributedPerOpen The number of reward units distributed per open.
//      *  @param packUri                  The metadata URI for packs.
//      */
//     // struct PackInfo {
//     //     PackContent[] contents;
//     //     uint128 openStartTimestamp;
//     //     uint128 amountDistributedPerOpen;
//     //     string uri;
//     // }

//     //mychange
//     //modified structs from IPack
//     struct PackContent {
//         Token token;
//         uint256 amountPerUnit;
//     }

//     struct PackInfo {
//         // BundleInfo bundle;
//         uint128 openStartTimestamp;
//         uint128 amountDistributedPerOpen;
//     }

//     /// @notice Emitted when a set of packs is created.
//     event PackCreated(uint256 indexed packId, address indexed packCreator, address recipient, PackInfo packInfo, uint256 totalPacksCreated);

//     /// @notice Emitted when a pack is opened.
//     event PackOpened(uint256 indexed packId, address indexed opener, uint256 numOfPacksOpened, PackContent[] rewardUnitsDistributed);

//     /// @dev Emitted when the owner is updated.
//     event OwnerUpdated(address prevOwner, address newOwner);

//     /**
//      *  @notice Creates a pack with the stated contents.
//      *
//      *  @param contents                 The reward units to pack in the packs.
//      *  @param packUri                  The (metadata) URI assigned to the packs created.
//      *  @param openStartTimestamp       The timestamp after which packs can be opened.
//      *  @param amountDistributedPerOpen The number of reward units distributed per open.
//      *  @param recipient                 The recipient of the packs created.
//      *
//      *  @return packId The unique identifer of the created set of packs.
//      *  @return packTotalSupply The total number of packs created.
//      */
//     function createPack(
//         PackContent[] calldata contents,
//         string calldata packUri,
//         uint128 openStartTimestamp,
//         uint128 amountDistributedPerOpen,
//         address recipient
//     ) external returns (uint256 packId, uint256 packTotalSupply);

//     /**
//      *  @notice Lets a pack owner open a pack and receive the pack's reward unit.
//      *
//      *  @param packId       The identifier of the pack to open.
//      *  @param amountToOpen The number of packs to open at once.
//      */
//     function openPack(uint256 packId, uint256 amountToOpen) external;
// }
