// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Wallet is ERC721Holder, ERC1155Holder {
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) public {
        IERC20(token).transfer(to, amount);
    }

    function transferERC721(
        address token,
        address to,
        uint256 tokenId
    ) public {
        IERC721(token).transferFrom(msg.sender, to, tokenId);
    }

    function transferERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        IERC1155(token).safeTransferFrom(msg.sender, to, tokenId, amount, data);
    }
}
