// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 *  `SignatureMint` is an ERC 721 contract. It lets anyone mint NFTs by producing a mint request
 *  and a signature (produced by an account with MINTER_ROLE, signing the mint request).
 */
interface ITokenERC721 is IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {

}
