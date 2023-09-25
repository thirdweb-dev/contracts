// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import { ERC721AQueryableUpgradeable } from "./queryable/ERC721AQueryableUpgradeable.sol";
import { ERC721AStorage } from "./queryable/ERC721AStorage.sol";

contract ERC721AExt is ERC721AQueryableUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                Modifier
    //////////////////////////////////////////////////////////////*/

    modifier onlySelf() {
        require(msg.sender == address(this), "!Self");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the current index i.e. next token ID to be minted.
    function currentIndex() external view returns (uint256) {
        return ERC721AStorage.layout()._currentIndex;
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
