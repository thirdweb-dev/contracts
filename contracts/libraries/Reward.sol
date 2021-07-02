// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

library Reward {
  enum RewardType { ERC20, ERC721, ERC1155 }

  struct ERC20Reward {
    address asset;
    uint totalTokenAmount;
    uint rewardTokenAmount;
  }

  struct ERC721Reward {
    address asset;
    uint tokenId;
  }

  struct ERC1155Reward {
    address asset;
    uint tokenId;
    uint totalTokenAmount;
    uint rewardTokenAmount;
  }
}