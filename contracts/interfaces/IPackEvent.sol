pragma solidity >=0.8.0;

interface IPackEvent {
  event PackCreated(address indexed creator, uint256 tokenId, uint256 maxSupply);
  event PackRewardsAdded(address indexed creator, uint256 tokenId, uint256[] rewardTokenIds);
  event PackOpened(address indexed owner, uint256 tokenId, uint256[] rewardTokenIds);
}
