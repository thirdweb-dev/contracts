// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  Features    ==========

import { PermissionsEnumerable } from "../feature/PermissionsEnumerable.sol";
import { SignatureMintERC721 } from "../feature/SignatureMintERC721.sol";
import "../feature/interface/IPermissions.sol";

contract SigMint is
    PermissionsEnumerable,
    SignatureMintERC721
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    )
        external
        payable
        onlyRole(OPERATOR_ROLE)
    {

        require(_req.quantity > 0, "minting zero tokens");

        // Verify and process payload.
        address signer = _processRequest(_req, _signature);

        emit TokensMintedWithSignature(signer, _req.to, _req);
    }

    /*///////////////////////////////////////////////////////////////
                    Contract specific function
    //////////////////////////////////////////////////////////////*/

    function claimOperatorRole() external {
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return IPermissions(msg.sender).hasRole(keccak256("MINTER_ROLE"), _signer);
    }
}
