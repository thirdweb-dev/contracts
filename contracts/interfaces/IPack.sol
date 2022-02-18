// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IThirdwebOwnable.sol";
import "./IThirdwebRoyalty.sol";

interface IPack is IThirdwebContract, IThirdwebOwnable, IThirdwebRoyalty {
    /**
     *  @notice A pack can contain ERC1155 tokens from n number of ERC1155 contracts.
     *          You can add any kinds of tokens to a pack via Multiwrap.
     */
    struct PackContents {
        address[] erc1155AssetContracts;
        uint256[][] erc1155TokensToWrap;
        uint256[][] erc1155AmountsToWrap;
    }

    /**
     *  @notice Creates a pack with the stated contents.
     *
     *  @param contents The contents of the packs to be created.
     *  @param uri The (metadata) URI assigned to the packs created.
     *  @param openStartTimestamp The timestamp after which a pack is opened.
     *  @param nftsPerOpen The number of NFTs received on opening one pack.
     */
    function createPack(
        PackContents calldata contents,
        string calldata uri,
        uint128 openStartTimestamp,
        uint128 nftsPerOpen
    ) external;

    /**
     *  @notice Lets a pack owner open a pack and receive the pack's NFTs.
     *
     *  @param packId The identifier of the pack to open.
     *  @param amountToOpen The number of packs to open at once.
     */
    function openPack(uint256 packId, uint256 amountToOpen) external;
}
