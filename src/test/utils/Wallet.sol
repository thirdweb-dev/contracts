// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";

contract Wallet is ERC721Holder, ERC1155Holder {
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) public {
        MockERC20(token).transfer(to, amount);
    }

    function setAllowanceERC20(
        address token,
        address spender,
        uint256 allowanceAmount
    ) public {
        MockERC20(token).approve(spender, allowanceAmount);
    }

    function burnERC20(address token, uint256 amount) public {
        MockERC20(token).burn(amount);
    }

    function transferERC721(
        address token,
        address to,
        uint256 tokenId
    ) public {
        MockERC721(token).transferFrom(address(this), to, tokenId);
    }

    function setApprovalForAllERC721(
        address token,
        address operator,
        bool toApprove
    ) public {
        MockERC721(token).setApprovalForAll(operator, toApprove);
    }

    function burnERC721(address token, uint256 tokenId) public {
        MockERC721(token).burn(tokenId);
    }

    function transferERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external {
        MockERC1155(token).safeTransferFrom(address(this), to, tokenId, amount, data);
    }

    function setApprovalForAllERC1155(
        address token,
        address operator,
        bool toApprove
    ) public {
        MockERC1155(token).setApprovalForAll(operator, toApprove);
    }

    function burnERC1155(
        address token,
        uint256 tokenId,
        uint256 amount
    ) public {
        MockERC1155(token).burn(address(this), tokenId, amount);
    }
}
