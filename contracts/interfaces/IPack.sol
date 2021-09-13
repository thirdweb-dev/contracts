// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IPack is IERC1155MetadataURI, IERC1155Receiver {
    /**
     * @notice Creates packs filled with the provided underlying rewards.
     *
     * @param _packURI The media URI of the pack.
     * @param _rewardContract The address of the rewards contract.
     * @param _rewardIds The tokenIds of the rewards being packed.
     * @param _rewardAmounts The amounts of each reward to pack.
     * @param _secondsUntilOpenStart The seconds from the time of pack creation, until when the pack can be opened.
     * @param _secondsUntilOpenEnd The seconds from the time of pack creation, until after when packs can no longer be opened.
     * @param _rewardsPerOpen The number of rewards distrubted every time a pack is opened.
     *
     * @dev Both `_rewardIds` and `_rewardAmounts` must be ordered i.e. `_rewardAmounts[i]` amount of the reward with tokenId
     * `_rewardIds[i]` is being packed.
     *
     * @return packId : The tokenId of the packs created.
     * @return packTotalSupply : The total supply of the packs minted.
     */
    function createPack(
        string calldata _packURI,
        address _rewardContract,
        uint256[] calldata _rewardIds,
        uint256[] calldata _rewardAmounts,
        uint256 _secondsUntilOpenStart,
        uint256 _secondsUntilOpenEnd,
        uint256 _rewardsPerOpen
    ) external returns (uint256 packId, uint256 packTotalSupply);

    /**
     * @notice Lets a pack owner open a pack for underlying rewards.
     *
     * @dev Sends a random number request to Chainlink VRF. This random number is later used
     *      to select the rewards to distribute to the pack opener.
     *
     * @param _packId The token ID of the pack to open.
     */
    function openPack(uint256 _packId) external;

    /**
     * @notice Called by the Chainlink VRF system to fulfill a randomness request.
     *
     * @param _requestId The request Id of a random number request.
     * @param _randomness The random number sent by the Chainlink VRF system.
     */
    function fulfillRandomness(uint256 _requestId, uint256 _randomness) external;

    /**
     * @notice Distributes rewards entitled to `_receiver` from `_receiver` opening a pack.
     *
     * @dev Transfers the reward tokens entitled to `_receiver`.
     *
     * @param _packId The tokenId of the pack for which the rewards are to be collected.
     * @param _receiver The relevant opener of the pack.
     */
    function collectRewards(uint256 _packId, address _receiver) external;

    /**
     * @notice Returns (for a given pack) the source of rewards, the tokenIds of the rewards and the amounts of each reward still packed.
     *
     * @param _packId The tokenId of a given set of packs.
     *
     * @return source : The source of the pack's underlying rewards.
     * @return tokenIds : The tokenIds of the pack's underlying rewards.
     * @return amountsPacked : The amounts of reach rewards still packed.
     */
    function getRewards(uint256 _packId)
        external
        view
        returns (
            address source,
            uint256[] memory tokenIds,
            uint256[] memory amountsPacked
        );
}
