// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
 * @dev Mock contract for typechain types generation purposes :)
 */
contract Mock {
    IERC20 public erc20;
    IERC721 public erc721;
    IERC1155 public erc1155;
}
