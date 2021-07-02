// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "./PackControl.sol";
import "./PackERC1155.sol";
import "./RewardERC1155.sol";

import "./libraries/Reward.sol";
import "./interfaces/RNGInterface.sol";

/**
 * The $PACK Protocol wraps arbitrary assets (ERC20, ERC721, ERC1155 tokens) into ERC 1155 reward tokens. These reward tokens are
 * bundled into ERC 1155 pack tokens. Opening a pack distributes a reward randomly selected from the pack to the opener. Both pack
 * and reward tokens can be airdropped or sold.
 */

contract Handler {

  PackControl internal packControl;

  string public constant REWARD_ERC1155_MODULE_NAME = "REWARD_ERC1155";
  string public constant PACK_ERC1155_MODULE_NAME = "PACK_ERC1155";
  string public constant PACK_RNG = "PACK_RNG";
  string public constant PACK_ASSET_MANAGER = "PACK_ASSET_MANAGER";

  struct Pack {
    uint[] rewardTokenIds;
    uint[] rarityNumerators;
  }

  struct RandomnessRequest {
    address packOpener;
    uint packId;
  }

  constructor(address _packControl) {
    packControl = PackControl(_packControl);
  }

  /// @dev Pack tokenId => Pack state.
  mapping(uint => Pack) internal packs;

  /// @dev RNG request Id => request state `RandomnessRequest`. 
  mapping(uint => RandomnessRequest) public randomnessRequests;

  /// @dev Creates a pack with rewards.
  function createPack(string calldata _packURI, uint[] calldata _rewardIds, uint[] calldata _amounts) external returns (uint packTokenId) {
    require(
      rewardERC1155().isApprovedForAll(msg.sender, address(this)), 
      "Must approve handler to transer the required reward tokens."
    );

    for(uint i = 0; i < _rewardIds.length; i++) {
      require(
        rewardERC1155().balanceOf(msg.sender, _rewardIds[i]) > _amounts[i],
        "Insufficient reward token balance to add rewards to the pack."
      );
    }

    // Transfer ERC 1155 reward tokens to this contract.
    rewardERC1155().safeBatchTransferFrom(msg.sender, address(this), _rewardIds, _amounts, "");

    // Get pack tokenId
    packTokenId = packERC1155()._tokenId();

    // Store pack state
    packs[packTokenId] = Pack({
      rewardTokenIds: _rewardIds,
      rarityNumerators: _amounts
    });

    // Mint pack tokens to `msg.sender`
    packERC1155().mintToken(msg.sender, packTokenId, sumArr(_amounts), _packURI);
  }

  /// @notice Lets a pack token owner open a single pack
  function openPack(uint packId) external {
    require(packERC1155().balanceOf(msg.sender, packId) > 0, "Sender owns no packs of the given packId.");

    if(rng().usingExternalService()) {
      // Approve RNG to handle fee amount of fee token.
      (address feeToken, uint feeAmount) = rng().getRequestFee();
      if(feeToken != address(0)) {
        require(
          IERC20(feeToken).approve(address(rng()), feeAmount),
          "Failed to approve rng to handle fee amount of fee token."
        );
      }
      // Request external service for a random number. Store the request ID and lockBlock.
      (uint requestId,) = rng().requestRandomNumber();

      randomnessRequests[requestId] = RandomnessRequest({
        packOpener: msg.sender,
        packId: packId
      });
    } else {
      
      (uint randomness,) = rng().getRandomNumber(block.number);
      uint rewardTokenId = getRandomReward(packId, randomness);
      
      distributeReward(msg.sender, packId, rewardTokenId);
    }
  }

  /// @dev Called by protocol RNG when using an external random number provider.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(rng()), "Only the appointed RNG can fulfill random number requests.");
    
    RandomnessRequest memory request = randomnessRequests[requestId];

    uint rewardTokenId = getRandomReward(request.packId, randomness);
    distributeReward(request.packOpener, request.packId, rewardTokenId);
  }

  /// @dev Wraps ERC 20 tokens as ERC 1155 reward tokens
  function wrapERC20(
    address _onBehalfOf,
    address _asset,
    uint _amount,
    uint _numOfRewardTokens
  ) external returns (uint rewardTokenId) {

    require(IERC20(_asset).balanceOf(_onBehalfOf) >= _amount, "Must own the amount of tokens to be wrapped.");
    require(IERC20(_asset).allowance(msg.sender, address(this)) >= _amount, "Must approve handler to transfer the given amount of tokens.");

    // Transfer the ERC 20 tokens to this contract.
    require(
      IERC20(_asset).transferFrom(msg.sender, address(this), _amount),
      "Failed to transfer the given amount of tokens."
    );

    // Get reward tokenId
    rewardTokenId = rewardERC1155()._tokenId();

    // TODO : STORE STATE

    // Mint reward token to `msg.sender`
    rewardERC1155().mintToken(
      msg.sender, 
      rewardTokenId, 
      _numOfRewardTokens, 
      "", 
      Reward.RewardType.ERC20
    );
  }

  /// @dev Wraps an ERC 721 token as a ERC 1155 reward token.
  function wrapERC721(address _tokenContract, uint _tokenId) external returns (uint rewardTokenId) {
    require(IERC721Metadata(_tokenContract).getApproved(_tokenId) == address(this), "Must approve handler to transfer the NFT.");

    // Transfer the NFT to this contract.
    IERC721Metadata(_tokenContract).safeTransferFrom(
      IERC721Metadata(_tokenContract).ownerOf(_tokenId), 
      address(this), 
      _tokenId
    );

    // Get reward tokenId
    rewardTokenId = rewardERC1155()._tokenId();

    // TODO : STORE STATE

    // Mint reward token to `msg.sender`
    rewardERC1155().mintToken(
      msg.sender, 
      rewardTokenId, 
      1, 
      IERC721Metadata(_tokenContract).tokenURI(_tokenId), 
      Reward.RewardType.ERC721
    );
  }

  /// @dev Wraps ERC 1155 tokens as ERC 1155 reward tokens.
  function wrapERC1155(address _tokenContract, uint _tokenId, uint _amount, uint _numOfRewardTokens) external returns (uint rewardTokenId) {
    require(
      IERC1155MetadataURI(_tokenContract).isApprovedForAll(msg.sender, address(this)), 
      "Must approve handler to transer the required tokens."
    );

    // Transfer the ERC 1155 tokens to this contract.
    IERC1155MetadataURI(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId , _amount, "");

    // Get reward tokenId
    rewardTokenId = rewardERC1155()._tokenId();

    // TODO : STORE STATE

    // Mint reward token to `msg.sender`
    rewardERC1155().mintToken(
      msg.sender, 
      rewardTokenId, 
      _numOfRewardTokens, 
      IERC1155MetadataURI(_tokenContract).uri(_tokenId), 
      Reward.RewardType.ERC1155
    );
  }

  /// @dev returns a random reward tokenId using `randomness` provided by Chainlink VRF.
  function getRandomReward(uint packId, uint randomness) internal returns (uint rewardTokenId) {

    uint prob = randomness % sumArr(packs[packId].rarityNumerators);
    uint step = 0;

    for(uint i = 0; i < packs[packId].rewardTokenIds.length; i++) {
      if(prob < (packs[packId].rarityNumerators[i] + step)) {
        
        rewardTokenId = packs[packId].rewardTokenIds[i];
        packs[packId].rarityNumerators[i] -= 1;

        break;
      } else {
        step += packs[packId].rarityNumerators[i];
      }
    }
  }

  /// @dev Distributes a reward token to the pack opener.
  function distributeReward(address _receiver, uint _packId, uint _rewardId) internal {
    // Burn the opened pack.
    packERC1155().burn(_receiver, _packId, 1);

    // Mint the appropriate reward token.
    rewardERC1155().safeTransferFrom(address(this), _receiver, _rewardId, 1, "");
  }

  /// @dev Returns pack protocol's reward ERC1155 contract.
  function rewardERC1155() internal view returns (RewardERC1155) {
    return RewardERC1155(packControl.getModule(REWARD_ERC1155_MODULE_NAME));
  }

  /// @dev Returns pack protocol's reward ERC1155 contract.
  function packERC1155() internal view returns (PackERC1155) {
    return PackERC1155(packControl.getModule(PACK_ERC1155_MODULE_NAME));
  }

  /// @dev Returns pack protocol's RNG.
  function rng() internal view returns (RNGInterface) {
    return RNGInterface(packControl.getModule(PACK_RNG));
  }

  /// @dev Returns pack protocol's asset manager address.
  function assetManager() internal view returns (address) {
    return packControl.getModule(PACK_ASSET_MANAGER);
  }

  /// @dev Returns the sum of all elements in the array
  function sumArr(uint[] memory arr) internal pure returns (uint sum) {
    for(uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
  }
}