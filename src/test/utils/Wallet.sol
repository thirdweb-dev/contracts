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

    function setAllowance20(
        address token,
        address spender,
        uint256 allowanceAmount
    ) public {
        IERC20(token).approve(spender, allowanceAmount);
    }

    function transferERC721(
        address token,
        address to,
        uint256 tokenId
    ) public {
        IERC721(token).transferFrom(address(this), to, tokenId);
    }

    function setApprovalForAll721(
        address token,
        address operator,
        bool toApprove
    ) public {
        IERC721(token).setApprovalForAll(operator, toApprove);
    }

    function transferERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        IERC1155(token).safeTransferFrom(address(this), to, tokenId, amount, data);
    }

    function setApprovalForAll1155(
        address token,
        address operator,
        bool toApprove
    ) public {
        IERC1155(token).setApprovalForAll(operator, toApprove);
    }
}
