// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./PackControl.sol";

pragma solidity ^0.8.0;

contract Asset is AccessControl, IERC1155Receiver, IERC721Receiver {

  PackControl internal packControl;

  string public constant PACK_HANDLER = "PACK_HANDLER";
  string public constant PACK_MARKET = "PACK_MARKET";

  constructor(address _packControl) {
    packControl = PackControl(_packControl);
    _setupRole(DEFAULT_ADMIN_ROLE, _packControl);
  }

  modifier onlyProtocolModules() {
    require(
      msg.sender == handler() || msg.sender == market() || msg.sender == address(packControl),
      "Only certain protocol modules may call this function."
    );
    _;
  }

  function approveERC20(address _asset, address _operator, uint _amount) external onlyProtocolModules {
    IERC20(_asset).approve(_operator, _amount);
  }

  function approveERC721(address _asset, address _operator, uint _tokenId) external onlyProtocolModules {
    IERC721(_asset).approve(_operator, _tokenId);
  }

  function approveERC1155(address _asset, address _operator) external onlyProtocolModules {
    IERC1155(_asset).setApprovalForAll(_operator, true);
  }

  function handler() internal view returns (address) {
    return packControl.getModule(PACK_HANDLER);
  }

  function market() internal view returns (address) {
    return packControl.getModule(PACK_MARKET);
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