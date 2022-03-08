// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebOwnable.sol";
import "./IThirdwebRoyalty.sol";

import "../lib/MultiTokenTransferLib.sol";

interface IPack is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {

    /**
     *  @notice The number of fungible tokens to distribute as a unit, on a pack open.
     */
    struct TokensPerOpen {
        uint256[] erc20TokensPerOpen;
        uint256[][] erc1155TokensPerOpen;
    }

    /// @dev The state of packs with a unique tokenId.
    struct PackState {
        string uri;
        uint256 openStartTimestamp;
        TokensPerOpen tokensPerOpen;
        MultiTokenTransferLib.MultiToken tokensPacked;
    }

    /**
     *  @notice Creates a pack with the stated contents.
     *
     *  @param tokensToPack The contents of the packs to be created.
     *  @param tokensPerOpen The number of erc20 and erc1155 tokens to distribute as a unit per pack open.
     *  @param uri The (metadata) URI assigned to the packs created.
     *  @param openStartTimestamp The timestamp after which a pack is opened.
     */
    function createPack(
        MultiTokenTransferLib.MultiToken calldata tokensToPack,
        TokensPerOpen calldata tokensPerOpen,
        string calldata uri,
        uint256 openStartTimestamp
    ) external returns (uint256 packId, uint256 packAmount);

    /**
     *  @notice Lets a pack owner open a pack and receive the pack's NFTs.
     *
     *  @param packId The identifier of the pack to open.
     *  @param amountToOpen The number of packs to open at once.
     */
    function openPack(uint256 packId, uint256 amountToOpen, address receiver) external;
}
