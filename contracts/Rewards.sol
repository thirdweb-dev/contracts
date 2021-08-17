// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Rewards is ERC1155 {

  /// @dev Address of $PACK Protocol's `pack` token.
  address public pack;

  /// @dev The token Id of the reward to mint.
  uint public nextTokenId;

  struct Reward {
    address creator;
    string uri;
    uint supply;
  }

  /// @notice Events.
  event RewardsCreated(address indexed creator, uint[] rewardIds, string[] rewardURIs, uint[] rewardSupplies);

  /// @dev Reward tokenId => Reward state.
  mapping(uint => Reward) public rewards;

  constructor(address  _pack) ERC1155("") {
    pack = _pack;
  }

	/// @dev Creates packs with rewards.
	function createPack(
		string[] calldata _rewardURIs,
		uint[] calldata _rewardSupplies,

		string calldata _packURI,
		uint _secondsUntilOpenStart,
    uint _secondsUntilOpenEnd

	) external {
		
		uint[] memory rewardIds = createRewards(_rewardURIs, _rewardSupplies);

		bytes memory args = abi.encode(_packURI, address(this), rewardIds, _rewardSupplies, _secondsUntilOpenStart, _secondsUntilOpenEnd);

		safeBatchTransferFrom(msg.sender, pack, rewardIds, _rewardSupplies, args);
	}

  /// @notice Create native ERC 1155 rewards.
  function createRewards(string[] calldata _rewardURIs, uint[] calldata _rewardSupplies) internal returns (uint[] memory rewardIds) {
    require(_rewardURIs.length == _rewardSupplies.length, "Rewards: Must specify equal number of URIs and supplies.");
    require(_rewardURIs.length > 0, "Rewards: Must create at least one reward.");

    // Get tokenIds.
    rewardIds = new uint[](_rewardURIs.length);
    
    // Store reward state for each reward.
    for(uint i = 0; i < _rewardURIs.length; i++) {
      rewardIds[i] = nextTokenId;

      rewards[nextTokenId] = Reward({
        creator: msg.sender,
        uri: _rewardURIs[i],
        supply: _rewardSupplies[i]
      });

      nextTokenId++;
    }

    // Mint reward tokens to `msg.sender`
    _mintBatch(msg.sender, rewardIds, _rewardSupplies, "");

    emit RewardsCreated(msg.sender, rewardIds, _rewardURIs, _rewardSupplies);
  }

  /// @dev Updates a token's total supply.
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    internal
    override
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    // Decrease total supply if tokens are being burned.
    if (to == address(0)) {

      for(uint i = 0; i < ids.length; i++) {
        rewards[ids[i]].supply -= amounts[i];
      }
    }
  }

  /// @dev See EIP 1155
  function uri(uint _rewardId) public view override returns (string memory) {
    return rewards[_rewardId].uri;
  }

  /// @dev Returns the creator of reward token
  function creator(uint _rewardId) external view returns (address) {
    return rewards[_rewardId].creator;
  }
}