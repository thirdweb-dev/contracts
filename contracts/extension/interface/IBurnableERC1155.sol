// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  `SignatureMint1155` is an ERC 1155 contract. It lets anyone mint NFTs by producing a mint request
 *  and a signature (produced by an account with MINTER_ROLE, signing the mint request).
 */
interface IBurnableERC1155 {
    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(address account, uint256 id, uint256 value) external;

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}
