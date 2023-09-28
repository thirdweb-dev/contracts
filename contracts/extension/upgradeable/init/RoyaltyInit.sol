// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { RoyaltyStorage, IRoyalty } from "../Royalty.sol";

contract RoyaltyInit {
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setupDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal {
        if (_royaltyBps > 10_000) {
            revert("Exceeds max bps");
        }

        RoyaltyStorage.Data storage data = RoyaltyStorage.data();

        data.royaltyRecipient = _royaltyRecipient;
        data.royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }
}
