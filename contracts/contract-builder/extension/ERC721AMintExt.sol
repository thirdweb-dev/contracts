// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721AStorage, ERC721AUpgradeable } from "../../eip/ERC721AUpgradeable.sol";

contract ERC721AMintExt is ERC721AUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                Modifier
    //////////////////////////////////////////////////////////////*/

    modifier onlySelf() {
        require(msg.sender == address(this), "ERC721AMintExt: !Self");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the current index i.e. next token ID to be minted.
    function currentIndex() external view returns (uint256) {
        return ERC721AStorage.erc721AStorage()._currentIndex;
    }

    /// @notice Returns the start token ID of the collection.
    function startTokenId() external view returns (uint256) {
        return _startTokenId();
    }

    /// @notice Mints new tokens.
    /// @dev Can only be called by self.
    function safeMint(address to, uint256 quantity) external onlySelf {
        _safeMint(to, quantity, "");
    }
}
