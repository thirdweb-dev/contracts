// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../inherit/internal/LazyMintInternal.sol";

contract TokenIdTrackerLazyMintExt is LazyMintInternal {
    function canMintQuantity(uint256 _currentTotalMinted, uint256 _quantitytoMint) internal view returns (bool) {
        return _currentTotalMinted + _quantitytoMint <= _nextTokenIdToLazyMint();
    }
}

contract TokenIdTrackerSharedMetadataExt is LazyMintInternal {
    function canMintQuantity(uint256, uint256) internal view returns (bool) {
        return true;
    }
}
