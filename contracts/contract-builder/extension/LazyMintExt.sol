// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/LazyMint.sol";
import "../../extension/upgradeable/DelayedReveal.sol";

import "../inherit/ERC2771ContextConsumer.sol";
import "../inherit/internal/PermissionsInternal.sol";

import "../../lib/TWStrings.sol";

contract LazyMintExt is LazyMint, DelayedReveal, ERC2771ContextConsumer, PermissionsInternal {
    using TWStrings for uint256;

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs (optionally delayed reveal).
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        if (_data.length > 0) {
            (bytes memory encryptedURI, bytes32 provenanceHash) = abi.decode(_data, (bytes, bytes32));
            if (encryptedURI.length != 0 && provenanceHash != "") {
                _setEncryptedData(nextTokenIdToLazyMint() + _amount, _data);
            }
        }

        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /// @dev Lets an account with `MINTER_ROLE` reveal the URI for a batch of 'delayed-reveal' NFTs.
    function reveal(uint256 _index, bytes calldata _key) external returns (string memory revealedURI) {
        if (!_canReveal()) {
            revert("Not authorized");
        }
        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    /*///////////////////////////////////////////////////////////////
                        Override: Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        // Check: minter role
        return _hasRole(keccak256("MINTER_ROLE"), _msgSender());
    }

    /// @dev Returns whether a hidden URI can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        // Check: minter role
        return _hasRole(keccak256("MINTER_ROLE"), _msgSender());
    }
}
