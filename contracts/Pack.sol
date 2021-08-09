// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface IProtocolControl {
  /// @dev Returns whether the pack protocol is paused.
  function systemPaused() external view returns (bool);

  /// @dev Access Control: hasRole()
  function hasRole(bytes32 role, address account) external view returns (bool);

  /// @dev Access control: PROTOCOL_ADMIN role
  function PROTOCOL_ADMIN() external view returns (bytes32);
}

contract Pack is ERC1155, IERC1155Receiver, VRFConsumerBase {

  /// @dev The $PACK Protocol control center.
  IProtocolControl internal controlCenter;

  /// @dev The tokenId for the next set of packs to be minted.
  uint public nextTokenId;

  /// @dev Chainlink VRF variables.
  uint public vrfFees;
  bytes32 public vrfKeyHash;
  
  /// @dev The state of packs with a unique tokenId.
  struct PackState {
    uint packId;
    address creator;
    string uri;
    uint currentSupply;

    uint openStart;
    uint openEnd;
  }

  /// @dev The rewards in a given set of packs with a unique tokenId.
  struct Rewards {
    address source;

    uint[] tokenIds;
    uint[] amountsPacked;
  }

  /// @dev The state of a random number request made to Chainlink VRF on opening a pack.
  struct RandomnessRequest {
    uint packId;
    address opener;
  }

  /// @dev pack tokenId => The state of packs with id `tokenId`.
  mapping(uint => PackState) public packs;

  /// @dev pack tokenId => rewards in pack with id `tokenId`.
  mapping(uint => Rewards) public rewards;

  /// @dev requestId => Chainlink VRF request state with id `requestId`.
  mapping(bytes32 => RandomnessRequest) public randomnessRequests;

  /// @dev pack tokenId => pack opener => whether there is a pending Chainlink VRF random number request.
  mapping(uint => mapping(address => bool)) public pendingRequests;

  /// @dev Emitted when a set of packs is created.
  event PackCreated(address indexed rewardContract, address indexed creator, PackState packState, Rewards rewards);
  /// @dev Emitted on a request to open a pack.
  event PackOpenRequest(uint indexed packId, address indexed opener, bytes32 requestId);
  /// @dev Emitted when a request to open a pack is fulfilled.
  event PackOpenFulfilled(uint indexed packId, address indexed opener, bytes32 requestId, address indexed rewardContract, uint rewardId);

  /// @dev Checks whether $PACK Protocol is paused.
  modifier onlyUnpausedProtocol() {
    require(!controlCenter.systemPaused(), "Pack: The protocol is paused.");
    _;
  }

  constructor(
    address _controlCenter,
    string memory _uri,

    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint _fees

  ) ERC1155(_uri) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    controlCenter = IProtocolControl(_controlCenter);

    vrfKeyHash = _keyHash;
    vrfFees = _fees;
  }

  /**
  *   ERC 1155 and ERC 1155 Receiver functions.
  **/

  function uri(uint _id) public view override returns (string memory) {
    return packs[_id].uri;
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
    packId = _newPackId();
    packTotalSupply = _sumArr(_rewardAmounts);

    // Transfer ERC 1155 reward tokens Pack Protocol's asset manager. Will revert if `msg.sender` does not own the given amounts of tokens.
    IERC1155(_rewardContract).safeBatchTransferFrom(msg.sender, address(this), _rewardIds, _rewardAmounts, "");

    // Store pack state.
    PackState memory packState = PackState({
      packId: packId,
      creator: msg.sender,
      uri: _packURI,
      currentSupply: packTotalSupply,
      openStart: block.timestamp + _secondsUntilOpenStart,
      openEnd: _secondsUntilOpenEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilOpenEnd
    });

    Rewards memory rewardsInPack = Rewards({
      source: _rewardContract,
      tokenIds: _rewardIds,
      amountsPacked: _rewardAmounts
    });

    packs[packId] = packState;
    rewards[packId] = rewardsInPack;
    
    // Mint packs to creator.
    _mint(msg.sender, packId, packTotalSupply, "");

    emit PackCreated(_rewardContract, msg.sender, packState, rewardsInPack);
  }

  /// @notice Lets a pack owner open a single pack.
  function openPack(uint _packId) external onlyUnpausedProtocol {

    require(LINK.balanceOf(address(this)) >= vrfFees, "Pack: Not enough LINK to fulfill randomness request.");
    require(balanceOf(msg.sender, _packId) > 0, "Pack: sender owns no packs of the given packId.");
    require(!(pendingRequests[_packId][msg.sender]), "Pack: must wait for the pending pack to be opened.");

    // Burn the pack being opened.
    _burn(msg.sender, _packId, 1);

    PackState memory packState = packs[_packId];

    require(
      block.timestamp >= packState.openStart && block.timestamp <= packState.openEnd, 
      "Pack: the window to open packs has not started or closed."
    );

    // Send random number request.
    bytes32 requestId = requestRandomness(vrfKeyHash, vrfFees);

    // Update state to reflect the Chainlink VRF request.
    randomnessRequests[requestId] = RandomnessRequest({
      packId: _packId,
      opener: msg.sender
    });

    pendingRequests[_packId][msg.sender] = true;

    emit PackOpenRequest(_packId, msg.sender, requestId);
  }

  /// @dev Called by Chainlink VRF with a random number, completing the opening of a pack.
  function fulfillRandomness(bytes32 _requestId, uint _randomness) internal override {
    
    RandomnessRequest memory request = randomnessRequests[_requestId];

    // Pending request completed
    pendingRequests[request.packId][request.opener] = false;

    // Get tokenId of the reward to distribute.
    Rewards memory rewardsInPack = rewards[request.packId];

    uint rewardId = getReward(request.packId, _randomness, rewardsInPack);

    // Distribute the reward to the pack opener.
    IERC1155(rewardsInPack.source).safeTransferFrom(address(this), request.opener, rewardId, 1, "");

    emit PackOpenFulfilled(request.packId, request.opener, _requestId, rewardsInPack.source, rewardId);
  }

  /// @dev Lets a protocol admin change the Chainlink VRF fee.
  function setChainlinkFees(uint _newFees) external {
    require(controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), msg.sender), "Pack: only a protocol admin set VRF fees.");
    vrfFees = _newFees;
  }

  /**
  *   Internal functions.
  **/

  /// @dev Returns a reward tokenId using `_randomness` provided by RNG.
  function getReward(uint _packId, uint _randomness, Rewards memory _rewardsInPack) internal returns (uint rewardTokenId) {

    uint prob = _randomness % _sumArr(_rewardsInPack.amountsPacked);
    uint step = 0;

    for(uint i = 0; i < _rewardsInPack.tokenIds.length; i += 1) {

      if(prob < (_rewardsInPack.amountsPacked[i] + step)) {
        
        // Return the reward's tokenId
        rewardTokenId = _rewardsInPack.tokenIds[i];
        
        // Update amount of reward available in pack.
        rewards[_packId].amountsPacked[i] -= 1;
        break;

      } else {
        step += _rewardsInPack.amountsPacked[i];
      }
    }
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
    virtual
    override
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    // Decrease total supply if tokens are being burned.
    if (to == address(0)) {

      for(uint i = 0; i < ids.length; i += 1) {
        packs[ids[i]].currentSupply -= amounts[i];
      }
    }
  }

  /// @dev Returns and then increments `currentTokenId`
  function _newPackId() internal returns (uint tokenId) {
    tokenId = nextTokenId;
    nextTokenId += 1;
  }

  /// @dev Returns the sum of all elements in the array
  function _sumArr(uint[] memory arr) internal pure returns (uint sum) {
    for(uint i = 0; i < arr.length; i += 1) {
      sum += arr[i];
    }
  }

  /**
  *   Getter functions.
  **/

  /// @dev Returns the creator of a set of packs
  function creator(uint _packId) external view returns (address) {
    return packs[_packId].creator;
  }

  /// @dev Returns a pack for the given pack tokenId
  function getPack(uint _packId) external view returns (PackState memory pack) {
    pack = packs[_packId];
  }

  /// @dev Returns the the underlying rewards of a pack
  function getRewardsInPack(uint _packId) external view returns (address source, uint[] memory tokenIds, uint[] memory amountsPacked) {
    source = rewards[_packId].source; 
    tokenIds = rewards[_packId].tokenIds;
    amountsPacked = rewards[_packId].amountsPacked;
  }

  /// @dev Returns a pack with its underlying rewards
  function getPackWithRewards(uint _packId) 
    external 
    view 
    returns (PackState memory pack, address source, uint[] memory tokenIds, uint[] memory amountsPacked) 
  {
    pack = packs[_packId];
    source = rewards[_packId].source; 
    tokenIds = rewards[_packId].tokenIds;
    amountsPacked = rewards[_packId].amountsPacked;
  }
}