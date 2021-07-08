// ░█████╗░  ░█████╗░  ░█████╗░  ███████╗  ░██████╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██╔════╝  ██╔════╝  ██╔════╝
// ███████║  ██║░░╚═╝  ██║░░╚═╝  █████╗░░  ╚█████╗░  ╚█████╗░
// ██╔══██║  ██║░░██╗  ██║░░██╗  ██╔══╝░░  ░╚═══██╗  ░╚═══██╗
// ██║░░██║  ╚█████╔╝  ╚█████╔╝  ███████╗  ██████╔╝  ██████╔╝
// ╚═╝░░╚═╝  ░╚════╝░  ░╚════╝░  ╚══════╝  ╚═════╝░  ╚═════╝░


// ██████╗░  ░█████╗░  ░█████╗░  ██╗░░██╗  ░██████╗
// ██╔══██╗  ██╔══██╗  ██╔══██╗  ██║░██╔╝  ██╔════╝
// ██████╔╝  ███████║  ██║░░╚═╝  █████═╝░  ╚█████╗░
// ██╔═══╝░  ██╔══██║  ██║░░██╗  ██╔═██╗░  ░╚═══██╗
// ██║░░░░░  ██║░░██║  ╚█████╔╝  ██║░╚██╗  ██████╔╝
// ╚═╝░░░░░  ╚═╝░░╚═╝  ░╚════╝░  ╚═╝░░╚═╝  ╚═════╝░

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AccessPacks is ERC1155PresetMinterPauser, IERC1155Receiver {

  uint public currentTokenId;

  enum UnderlyingType { None, ERC20, ERC721, ERC1155 }

  struct AccessRewards {
    address creator;
    string uri;
    uint supply;
    UnderlyingType underlyingType;
  }

  struct ERC721Reward {
    address nftContract;
    uint nftTokenId;
  }

  struct ERC20Reward {
    address tokenContract;
    uint numOfRewards;
    uint underlyingTokenAmount;
  }

  /// @notice Pack and reward events.
  event RewardsCreated(uint[] rewardIds, string[] rewardURIs, uint[] rewardSupplies);

  /// @dev Reward tokenId => Reward state.
  mapping(uint => AccessRewards) public rewards;

  /// @dev Reward tokenId => Underlying ERC721 reward state.
  mapping(uint => ERC721Reward) public erc721Rewards;

  /// @dev Reward tokenId => Underlying ERC20 reward state.
  mapping(uint => ERC20Reward) public erc20Rewards;

  constructor() ERC1155PresetMinterPauser("") {
    _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
    revokeRole(MINTER_ROLE, msg.sender);
    revokeRole(PAUSER_ROLE, msg.sender);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @notice Lets `msg.sender` create a pack with rewards and list it for sale.
  function createNativeRewards(string[] calldata _rewardURIs, uint[] calldata _rewardSupplies) external returns (uint[] memory rewardIds) {

    require(_rewardURIs.length == _rewardSupplies.length, "Must specify equal number of URIs and supplies.");

    // Get tokenIds and store reward state.
    rewardIds = new uint[](_rewardURIs.length);
    
    for(uint i = 0; i < _rewardURIs.length; i++) {
      rewardIds[i] = currentTokenId;

      rewards[currentTokenId] = AccessRewards({
        creator: msg.sender,
        uri: _rewardURIs[i],
        supply: _rewardSupplies[i],
        underlyingType: UnderlyingType.None
      });

      currentTokenId++;
    }

    // Mint reward tokens to `msg.sender`
    _setupRole(MINTER_ROLE, msg.sender);
    mintBatch(msg.sender, rewardIds, _rewardSupplies, "");
    revokeRole(MINTER_ROLE, msg.sender);

    emit RewardsCreated(rewardIds, _rewardURIs, _rewardSupplies);
  }

  /// @dev Wraps an ERC721 NFT as ERC1155 reward tokens. 
  function wrapERC721(address _nftContract, uint _tokenId, string calldata _rewardURI) external {
    require(
      IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
      "Only the owner of the NFT can wrap it."
    );
    require(
      IERC721(_nftContract).getApproved(_tokenId) == address(this),
      "Must approve the contract to transfer the NFT."
    );
        
    // Transfer the NFT to this contract.
    IERC721(_nftContract).safeTransferFrom(
      msg.sender, 
      address(this), 
      _tokenId
    );

    // Mint reward tokens to `msg.sender`
    _setupRole(MINTER_ROLE, msg.sender);
    mint(msg.sender, currentTokenId, 1, "");
    revokeRole(MINTER_ROLE, msg.sender); 

    // Store reward state.
    rewards[currentTokenId] = AccessRewards({
      creator: msg.sender,
      uri: _rewardURI,
      supply: 1,
      underlyingType: UnderlyingType.ERC721
    });       
        
    // Map the reward tokenId to the underlying NFT
    erc721Rewards[currentTokenId] = ERC721Reward({
      nftContract: _nftContract,
      nftTokenId: _tokenId
    });

    currentTokenId++;
  }
  
  /// @dev Lets the reward owner redeem their ERC721 NFT.
  function redeemERC721(uint _rewardId) external {
    require(balanceOf(msg.sender, _rewardId) > 0, "Cannot redeem a reward you do not own.");
        
    // Burn the reward token
    burn(msg.sender, _rewardId, 1);
        
    // Transfer the NFT to `msg.sender`
    IERC721(erc721Rewards[_rewardId].nftContract).safeTransferFrom(
      address(this), 
      msg.sender,
      erc721Rewards[_rewardId].nftTokenId
    );
  }

  /// @dev Wraps ERC20 tokens as ERC1155 reward tokens.
  function wrapERC20(address _tokenContract, uint _tokenAmount, uint _numOfRewardsToMint, string calldata _rewardURI) external {

    require(
      IERC20(_tokenContract).allowance(msg.sender, address(this)) >= _tokenAmount,
      "Must approve this contract to transfer ERC20 tokens."
    );

    IERC20(_tokenContract).transferFrom(msg.sender, address(this), _tokenAmount);

    // Mint reward tokens to `msg.sender`
    _setupRole(MINTER_ROLE, msg.sender);
    mint(msg.sender, currentTokenId, _numOfRewardsToMint, "");
    revokeRole(MINTER_ROLE, msg.sender); 

    rewards[currentTokenId] = AccessRewards({
      creator: msg.sender,
      uri: _rewardURI,
      supply: _numOfRewardsToMint,
      underlyingType: UnderlyingType.ERC721
    });

    erc20Rewards[currentTokenId] = ERC20Reward({
      tokenContract: _tokenContract,
      numOfRewards: _numOfRewardsToMint,
      underlyingTokenAmount: _tokenAmount
    });
    
    currentTokenId++;    
  }

  /// @dev Lets the reward owner redeem their ERC20 tokens.
  function redeemERC20(uint _rewardId, uint _amount) external {
    require(balanceOf(msg.sender, _rewardId) > _amount, "Cannot redeem a reward you do not own.");
        
    // Burn the reward token
    burn(msg.sender, _rewardId, _amount);

    // Transfer the ERC20 tokens to `msg.sender` 
    IERC20(erc20Rewards[_rewardId].tokenContract).transferFrom(
      address(this), 
      msg.sender,
      (erc20Rewards[_rewardId].underlyingTokenAmount * _amount) / erc20Rewards[_rewardId].numOfRewards
    );
  }

  /// @dev See EIP 1155
  function uri(uint _rewardId) public view override returns (string memory) {
    return rewards[_rewardId].uri;
  }

  /// @dev Returns the creator of reward token
  function creator(uint _rewardId) external view returns (address) {
    return rewards[_rewardId].creator;
  }

  /// @dev See `IERC1155Receiver.sol`
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  /// @dev See `IERC1155Receiver.sol`
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }
}