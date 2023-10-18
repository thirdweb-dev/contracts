// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "../../extension/interface/ITokenBundle.sol";

/**
 *  The thirdweb `Pack` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into
 *  a set of packs. A pack can then be opened in return for a selection of the tokens in the pack. The selection of tokens distributed
 *  on opening a pack depends on the relative supply of all tokens in the packs.
 */

interface IPack is ITokenBundle {
    /**
     *  @notice All info relevant to packs.
     *
     *  @param perUnitAmounts           Mapping from a UID -> to the per-unit amount of that asset i.e. `Token` at that index.
     *  @param openStartTimestamp       The timestamp after which packs can be opened.
     *  @param amountDistributedPerOpen The number of reward units distributed per open.
     */
    struct PackInfo {
        uint256[] perUnitAmounts;
        uint128 openStartTimestamp;
        uint128 amountDistributedPerOpen;
    }

    /// @notice Emitted when a set of packs is created.
    event PackCreated(uint256 indexed packId, address recipient, uint256 totalPacksCreated);

    /// @notice Emitted when more packs are minted for a packId.
    event PackUpdated(uint256 indexed packId, address recipient, uint256 totalPacksCreated);

    /// @notice Emitted when a pack is opened.
    event PackOpened(
        uint256 indexed packId,
        address indexed opener,
        uint256 numOfPacksOpened,
        Token[] rewardUnitsDistributed
    );

    /**
     *  @notice Creates a pack with the stated contents.
     *
     *  @param contents                 The reward units to pack in the packs.
     *  @param numOfRewardUnits         The number of reward units to create, for each asset specified in `contents`.
     *  @param packUri                  The (metadata) URI assigned to the packs created.
     *  @param openStartTimestamp       The timestamp after which packs can be opened.
     *  @param amountDistributedPerOpen The number of reward units distributed per open.
     *  @param recipient                The recipient of the packs created.
     *
     *  @return packId The unique identifier of the created set of packs.
     *  @return packTotalSupply The total number of packs created.
     */
    function createPack(
        Token[] calldata contents,
        uint256[] calldata numOfRewardUnits,
        string calldata packUri,
        uint128 openStartTimestamp,
        uint128 amountDistributedPerOpen,
        address recipient
    ) external payable returns (uint256 packId, uint256 packTotalSupply);

    /**
     *  @notice Lets a pack owner open a pack and receive the pack's reward unit.
     *
     *  @param packId       The identifier of the pack to open.
     *  @param amountToOpen The number of packs to open at once.
     */
    function openPack(uint256 packId, uint256 amountToOpen) external returns (Token[] memory);
}
