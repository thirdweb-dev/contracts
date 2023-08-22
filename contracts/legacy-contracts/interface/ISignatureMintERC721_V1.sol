// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "../../prebuilts/interface/token/ITokenERC721.sol";

interface ISignatureMintERC721_V1 {
    function mintWithSignature(ITokenERC721.MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (uint256 tokenIdMinted);

    function verify(ITokenERC721.MintRequest calldata _req, bytes calldata _signature)
        external
        view
        returns (bool, address);
}
