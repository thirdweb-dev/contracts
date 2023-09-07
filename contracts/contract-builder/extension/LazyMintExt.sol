// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/LazyMint.sol";
import "../../extension/upgradeable/ERC2771ContextConsumer.sol";
import "../../extension/interface/IPermissions.sol";

import "../../lib/TWStrings.sol";

contract LazyMintExt is LazyMint, ERC2771ContextConsumer {
    using TWStrings for uint256;

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*///////////////////////////////////////////////////////////////
                        Override: Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        // Check: minter role
        try IPermissions(address(this)).hasRole(keccak256("MINTER_ROLE"), _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
