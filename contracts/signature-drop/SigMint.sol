// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  Features    ==========

import { SignatureMintERC721 } from "../feature/SignatureMintERC721.sol";
import { IPermissions } from "../feature/interface/IPermissions.sol";

contract SigMint is SignatureMintERC721 {
    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer)
    {
        require(_req.quantity > 0, "minting zero tokens");

        // Verify and process payload.
        signer = _processRequest(_req, _signature);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return IPermissions(msg.sender).hasRole(keccak256("MINTER_ROLE"), _signer);
    }
}
