// SPDX-License-Identifier: GPL-3.0 

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./PackControl.sol";
import "./PackERC1155.sol";
import "./RewardERC1155.sol";

// The $PACK Protocol wraps arbitrary assets (ERC20, ERC721, ERC1155 tokens) into ERC 1155 reward tokens. Combinations of these reward 
// tokens are bundled into ERC 1155 pack tokens. Opening a pack distributes a reward randomly selected from the pack to the opener. Both pack 
// and reward tokens can be airdropped or sold.

contract Handler {

  PackControl internal packControl;
  string public constant REWARD_ERC1155_MODULE_NAME = "REWARD_ERC1155";

  enum RewardType { ERC20, ERC721, ERC1155 }

  struct ERC721Reward {
    address nftContract;
    uint rewardTokenId;
  }

  struct ERC20Reward {
    address _asset;
    uint totalTokenAmount;
    uint rewardTokenAmount;
  }


  event RewardCreated(address creator, RewardType rewardType);

  constructor(address _packControl) {
    packControl = PackControl(_packControl);
  }

  /// @dev Wraps ERC 20 tokens as ERC 1155 reward tokens
  function wrapERC20(address _asset, uint _amount, uint _numOfRewardTokens) public returns (uint rewardTokenId) {
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
      uint(RewardType.ERC20)
    );

    emit RewardCreated(msg.sender, RewardType.ERC20);
  }

  /// @dev Wraps an ERC 721 token as a ERC 1155 reward token.
  function wrapERC721(address _tokenContract, uint _tokenId) public returns (uint rewardTokenId) {
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
      uint(RewardType.ERC721)
    );

    emit RewardCreated(msg.sender, RewardType.ERC721);
  }

  /// @dev Wraps ERC 1155 tokens as ERC 1155 reward tokens.
  function wrapERC1155(address _tokenContract, uint _tokenId, uint _amount, uint _numOfRewardTokens) public returns (uint rewardTokenId) {
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
      uint(RewardType.ERC1155)
    );

    emit RewardCreated(msg.sender, RewardType.ERC1155);
  }

  /// @dev Returns pack protocol's reward ERC1155 contract.
  function rewardERC1155() internal view returns (RewardERC1155) {
    return RewardERC1155(packControl.getModule(REWARD_ERC1155_MODULE_NAME));
  }

}