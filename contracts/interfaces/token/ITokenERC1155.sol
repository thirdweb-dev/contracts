// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

/**
 *  `SignatureMint1155` is an ERC 1155 contract. It lets anyone mint NFTs by producing a mint request
 *  and a signature (produced by an account with MINTER_ROLE, signing the mint request).
 */
interface ITokenERC1155 is IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    /// @dev The total circulating supply of tokens of ID `tokenId`
    function totalSupply(uint256 id) external view returns (uint256 supply);
}
