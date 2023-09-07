// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../extension/upgradeable/LazyMint.sol";
import "../../extension/upgradeable/DelayedReveal.sol";
import "../../extension/upgradeable/ERC2771ContextConsumer.sol";
import "../../extension/interface/IPermissions.sol";

import "../../lib/TWStrings.sol";

contract LazyMintDelayedRevealExt is LazyMint, DelayedReveal, ERC2771ContextConsumer {
    using TWStrings for uint256;

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        (uint256 batchId, ) = _getBatchId(_tokenId);
        string memory batchUri = _getBaseURI(_tokenId);

        if (isEncryptedBatch(batchId)) {
            return string(abi.encodePacked(batchUri, "0"));
        } else {
            return string(abi.encodePacked(batchUri, _tokenId.toString()));
        }
    }

    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint();
    }

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
        try IPermissions(address(this)).hasRole(keccak256("MINTER_ROLE"), _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }

    /// @dev Returns whether a hidden URI can be revealed in the given execution context.
    function _canReveal() internal view virtual returns (bool) {
        // Check: minter role
        try IPermissions(address(this)).hasRole(keccak256("MINTER_ROLE"), _msgSender()) returns (bool success) {
            return success;
        } catch {}

        return false;
    }
}
