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
  event PackCreated(address indexed rewardContract, address indexed creator, uint packId, string packURI, uint packTotalSupply);
  event PackRewards(uint indexed packId, address indexed rewardContract, uint[] rewardIds, uint[] rewardAmounts);
  event PackOpened(uint indexed packId, address indexed opener);
  event RewardDistributed(address indexed rewardContract, address indexed receiver, uint packId, uint rewardId);

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

  function uri(uint id) public view override returns (string memory) {
    return tokenURI[id];
  }

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
  *   Public functions.   
  **/

  /// @dev Creates packs with rewards.
  function createPack(
    string calldata _packURI,

    address _rewardContract, 
    uint[] calldata _rewardIds, 
    uint[] calldata _rewardAmounts,

    uint _secondsUntilOpenStart,
    uint _secondsUntilOpenEnd

  ) public onlyUnpausedProtocol returns (uint packId, uint packTotalSupply) {

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

    emit PackCreated(_rewardContract, msg.sender, packId, _packURI, packTotalSupply);
    emit PackRewards(packId, _rewardContract, _rewardIds, _rewardAmounts);
  }

  /**
  *   External functions.   
  **/

  /// @notice Lets a pack owner open a single pack.
  function openPack(uint _packId) external {

    require(block.timestamp >= openLimit[_packId].start && block.timestamp <= openLimit[_packId].end, "Pack: the window to open packs has not started or closed.");
    require(balanceOf(msg.sender, _packId) > 0, "Pack: sender owns no packs of the given packId.");
    require(!pendingRandomnessRequests[_packId][msg.sender], "Pack: must wait for the pending pack to be opened.");

    if(rng().usingExternalService()) {
      // If RNG is using an external service, open the pack upon retrieving the random number.
      asyncOpenPack(msg.sender, _packId);
    } else {
      // Else, open the pack right away. 
      syncOpenPack(msg.sender, _packId);
    }
  }

  /// @dev Called by protocol RNG when using an external random number provider. Completes a pack opening.
  function fulfillRandomness(uint requestId, uint randomness) external {
    require(msg.sender == address(rng()), "Pack: only the appointed RNG can fulfill random number requests.");

    // Pending request completed
    pendingRandomnessRequests[randomnessRequests[requestId].packId][randomnessRequests[requestId].opener] = false;

    // Burn the pack being opened.
    _burn(msg.sender, randomnessRequests[requestId].packId, 1);

    emit PackOpened(randomnessRequests[requestId].packId, msg.sender);

    // Get tokenId of the reward to distribute.
    uint rewardId = getReward(randomnessRequests[requestId].packId, randomness);
    address rewardContract = rewards[randomnessRequests[requestId].packId].source;

    // Distribute the reward to the pack opener.
    IERC1155(rewardContract).safeTransferFrom(address(this), randomnessRequests[requestId].opener, rewardId, 1, "");

    emit RewardDistributed(rewardContract, randomnessRequests[requestId].opener, randomnessRequests[requestId].packId, rewardId);
  }

  /**
  *   Internal functions.
  **/

  /// @dev Opens a pack i.e. burns a pack and distributes a reward to the pack opener.
  function syncOpenPack(address _opener, uint _packId) internal {

    // Burn the pack being opened.
    _burn(_opener, _packId, 1);

    emit PackOpened(_packId, _opener);

    // Get random number.
    (uint randomness,) = rng().getRandomNumber(block.number);
    
    // Get tokenId of the reward to distribute.
    uint rewardId = getReward(_packId, randomness);
    address rewardContract = rewards[_packId].source;

    // Distribute the reward to the pack opener.
    IERC1155(rewardContract).safeTransferFrom(address(this), _opener, rewardId, 1, "");

    emit RewardDistributed(rewardContract, _opener, _packId, rewardId);
  }

  /// @dev Initiates a pack opening; sends a random number request to an external RNG service.
  function asyncOpenPack(address _opener, uint _packId) internal {
    // Approve RNG to handle fee amount of fee token.
    (address feeToken, uint feeAmount) = rng().getRequestFee();

    if(feeToken != address(0)) {
      require(
        IERC20(feeToken).approve(address(rng()), feeAmount),
        "Pack: failed to approve rng to handle fee amount of fee token."
      );
    }

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
}