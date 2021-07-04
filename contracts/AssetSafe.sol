// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./ControlCenter.sol";

pragma solidity ^0.8.0;

contract AssetSafe is AccessControl, IERC1155Receiver, IERC721Receiver {

  ControlCenter internal controlCenter;

  string public constant HANDLER = "HANDLER";
  string public constant MARKET = "MARKET";

  constructor(address _controlCenter) {
    controlCenter = ControlCenter(_controlCenter);
    _setupRole(DEFAULT_ADMIN_ROLE, _controlCenter);
  }

  modifier onlyProtocolModules() {
    require(
      msg.sender == handler() || msg.sender == market() || msg.sender == address(controlCenter),
      "Only certain protocol modules may call this function."
    );
    _;
  }

  function transferERC20(address _asset, address _to, uint _amount) external onlyProtocolModules {
    IERC20(_asset).transfer(_to, _amount);
  }

  function transferERC721(address _asset, address _to, uint _tokenId) external onlyProtocolModules {
    IERC721(_asset).safeTransferFrom(address(this), _to, _tokenId);
  }

  function transferERC1155(address _asset, address _to, uint _tokenId, uint _amount) external onlyProtocolModules {
    IERC1155(_asset).safeTransferFrom(address(this), _to, _tokenId, _amount, "");
  }

  function handler() internal view returns (address) {
    return controlCenter.getModule(HANDLER);
  }

  function market() internal view returns (address) {
    return controlCenter.getModule(MARKET);
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

  /// @dev See `IERC721Receiver.sol` 
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}