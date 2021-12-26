// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

// Royalties
import "../royalty/RoyaltyReceiver.sol";

contract MockERC1155Royalty is ERC1155PresetMinterPauser, RoyaltyReceiver {
    constructor(address _royaltyReceiver)
        ERC1155PresetMinterPauser("ipfs://BaseURI")
        RoyaltyReceiver(_royaltyReceiver, 0)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155PresetMinterPauser, RoyaltyReceiver)
        returns (bool)
    {
        return
            ERC1155PresetMinterPauser.supportsInterface(interfaceId) || RoyaltyReceiver.supportsInterface(interfaceId);
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setRoyaltyBps(uint256 _royaltyBps) public {
        _setRoyaltyBps(_royaltyBps);
    }

    /// @dev Lets a module admin set the royalty recipient.
    function setRoyaltyRecipient(address _royaltyRecipient) public {
        _setRoyaltyRecipient(_royaltyRecipient);
    }
}
