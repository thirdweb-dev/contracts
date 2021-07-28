// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IProtocolControl, IRNG } from "./Interfaces.sol";

contract Pack is ERC1155, IERC1155Receiver {

  /// @dev The pack protocol admin contract.
  IProtocolControl internal controlCenter;

  /// @dev Pack protocol module names.
  string public constant RNG = "RNG";
  string public constant MARKET = "MARKET";

  /// @dev The tokenId for packs to be minted.
  uint public nextTokenId;

  struct PackInfo {
    uint packId;
    address creator;
    string uri;
    uint currentSupply;

    uint openStart;
    uint openEnd;
  }

  struct Rewards {
    address source;

    uint[] tokenIds;
    uint[] amountsPacked;
  }

  struct Open {
    uint start;
    uint end;
  }

  struct RandomnessRequest {
    address opener;
    uint packId;
  }

  /// @dev tokenId => token creator.
  mapping(uint => address) public creator;

  /// @dev tokenId => token URI.
  mapping(uint => string) public tokenURI;

  /// @dev tokenId => total supply of token.
  mapping(uint => uint) public totalSupply;

  /// @dev tokenId => rewards in pack.
  mapping(uint => Rewards) public rewards;

  /// @dev tokenId => time limits on on when you can open a pack.
  mapping(uint => Open) public openLimit;

  /// @dev requestId => Randomness request state.
  mapping(uint => RandomnessRequest) public randomnessRequests;

  /// @dev packId => any pending randomness requests.
  mapping(uint => mapping(address => bool)) public pendingRandomnessRequests;

  /// @dev Events.
  event PackCreated(address indexed rewardContract, address indexed creator, uint packId, string packURI, uint packTotalSupply, uint openStart, uint openEnd);
  event PackRewards(uint indexed packId, address indexed rewardContract, uint[] rewardIds, uint[] rewardAmounts);
  event PackOpened(uint indexed packId, address indexed opener);
  event RewardDistributed(address indexed rewardContract, address indexed receiver, uint indexed packId, uint rewardId);

  /// @dev Checks whether Pack protocol is paused.
  modifier onlyUnpausedProtocol() {
    require(!controlCenter.systemPaused(), "Pack: The pack protocol is paused.");
    _;
  }

  constructor(address _controlCenter, string memory _uri) ERC1155(_uri) {
    controlCenter = IProtocolControl(_controlCenter);
  }

  /**
  *   ERC 1155 and ERC 1155 Receiver functions.
  **/

  function uri(uint _id) public view override returns (string memory) {
    return tokenURI[_id];
  }

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
  *   External functions.   
  **/

  /// @dev Creates packs with rewards.
  function createPack(
    string calldata _packURI,

    address _rewardContract, 
    uint[] calldata _rewardIds, 
    uint[] calldata _rewardAmounts,

    uint _secondsUntilOpenStart,
    uint _secondsUntilOpenEnd

  ) external onlyUnpausedProtocol returns (uint packId, uint packTotalSupply) {

    require(IERC1155(_rewardContract).supportsInterface(0xd9b67a26), "Pack: reward contract does not implement ERC 1155.");
    require(_rewardIds.length == _rewardAmounts.length, "Pack: unequal number of reward IDs and reward amounts provided.");
    require(IERC1155(_rewardContract).isApprovedForAll(msg.sender, address(this)), "Pack: not approved to transer the reward tokens.");

    // Get pack tokenId and total supply.
    packId = _tokenId();
    packTotalSupply = _sumArr(_rewardAmounts);

    // Transfer ERC 1155 reward tokens Pack Protocol's asset manager. Will revert if `msg.sender` does not own the given amounts of tokens.
    IERC1155(_rewardContract).safeBatchTransferFrom(msg.sender, address(this), _rewardIds, _rewardAmounts, "");

    // Store pack state.
    creator[packId] = msg.sender;
    tokenURI[packId] = _packURI;
    
    rewards[packId] = Rewards({
      source: _rewardContract,
      tokenIds: _rewardIds,
      amountsPacked: _rewardAmounts
    });

    openLimit[packId] = Open({
      start: block.timestamp + _secondsUntilOpenStart,
      end: _secondsUntilOpenEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilOpenEnd
    });

    // Mint packs to creator.
    _mint(msg.sender, packId, packTotalSupply, "");

    emit PackCreated(_rewardContract, msg.sender, packId, _packURI, packTotalSupply, openLimit[packId].start, openLimit[packId].end);
    emit PackRewards(packId, _rewardContract, _rewardIds, _rewardAmounts);
  }

  /// @notice Lets a pack owner open a single pack.
  function openPack(uint _packId) external {

    require(block.timestamp >= openLimit[_packId].start && block.timestamp <= openLimit[_packId].end, "Pack: the window to open packs has not started or closed.");
    require(balanceOf(msg.sender, _packId) > 0, "Pack: sender owns no packs of the given packId.");
    require(!pendingRandomnessRequests[_packId][msg.sender], "Pack: must wait for the pending pack to be opened.");

    asyncOpenPack(msg.sender, _packId);
  }

  /// @dev Called by protocol RNG when using an external random number provider. Completes a pack opening.
  function fulfillRandomness(uint _requestId, uint _randomness) external {
    require(msg.sender == address(rng()), "Pack: only the appointed RNG can fulfill random number requests.");

    // Pending request completed
    pendingRandomnessRequests[randomnessRequests[_requestId].packId][randomnessRequests[_requestId].opener] = false;

    // Burn the pack being opened.
    _burn(msg.sender, randomnessRequests[_requestId].packId, 1);

    emit PackOpened(randomnessRequests[_requestId].packId, msg.sender);

    // Get tokenId of the reward to distribute.
    uint rewardId = getReward(randomnessRequests[_requestId].packId, _randomness);
    address rewardContract = rewards[randomnessRequests[_requestId].packId].source;

    // Distribute the reward to the pack opener.
    IERC1155(rewardContract).safeTransferFrom(address(this), randomnessRequests[_requestId].opener, rewardId, 1, "");

    emit RewardDistributed(rewardContract, randomnessRequests[_requestId].opener, randomnessRequests[_requestId].packId, rewardId);
  }

  /**
  *   Internal functions.
  **/

  /// @dev Initiates a pack opening; sends a random number request to an external RNG service.
  function asyncOpenPack(address _opener, uint _packId) internal {
    // Request external service for a random number. Store the request ID.
    (uint requestId,) = rng().requestRandomNumber();

    randomnessRequests[requestId] = RandomnessRequest({
      opener: _opener,
      packId: _packId
    });

    pendingRandomnessRequests[_packId][_opener] = true;
  }

  /// @dev Returns a reward tokenId using `_randomness` provided by RNG.
  function getReward(uint _packId, uint _randomness) internal returns (uint rewardTokenId) {

    uint prob = _randomness % _sumArr(rewards[_packId].amountsPacked);
    uint step = 0;

    for(uint i = 0; i < rewards[_packId].tokenIds.length; i++) {

      if(prob < (rewards[_packId].amountsPacked[i] + step)) {
        
        rewardTokenId = rewards[_packId].tokenIds[i];
        rewards[_packId].amountsPacked[i] -= 1;
        break;

      } else {
        step += rewards[_packId].amountsPacked[i];
      }
    }
  }

  /// @dev Updates a token's total supply.
  function _beforeTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  )
    internal
    override
  {
    // Increase total supply if tokens are being minted.
    if(from == address(0)) {
      
      for(uint i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] += amounts[i];
      }

      // Decrease total supply if tokens are being burned.
    } else if (to == address(0)) {

      for(uint i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] -= amounts[i];
      }
    }
  }

  /// @dev Returns and then increments `currentTokenId`
  function _tokenId() internal returns (uint tokenId) {
    tokenId = nextTokenId;
    nextTokenId += 1;
  }

  /// @dev Returns pack protocol's RNG.
  function rng() internal view returns (IRNG) {
    return IRNG(controlCenter.getModule(RNG));
  }

  /// @dev Returns the sum of all elements in the array
  function _sumArr(uint[] memory arr) internal pure returns (uint sum) {
    for(uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
  }

  /**
  *   Getter functions.
  **/

  /// @dev Returns a pack for the given pack tokenId
  function getPackById(uint _packId) external view returns (PackInfo memory pack) {
    pack = PackInfo({
      packId: _packId,
      creator: creator[_packId],
      uri: tokenURI[_packId],
      currentSupply: totalSupply[_packId],
      openStart: openLimit[_packId].start,
      openEnd: openLimit[_packId].end
    });
  }

  /// @dev Returns the the underlying rewards of a pack
  function getRewards(uint _packId) external view returns (address source, uint[] memory tokenIds, uint[] memory amountsPacked) {
    source = rewards[_packId].source; 
    tokenIds = rewards[_packId].tokenIds;
    amountsPacked = rewards[_packId].amountsPacked;
  }
}