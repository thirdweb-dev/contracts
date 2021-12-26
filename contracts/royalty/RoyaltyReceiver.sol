// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract RoyaltyReceiver is IERC2981 {
    address public royaltyReceiver;
    uint96 public royaltyBps;

    /// @dev Emitted when the royalty fee bps is updated
    event RoyaltyUpdated(uint96 newRoyaltyBps);

    constructor(address _receiver, uint96 _royaltyBps) {
        royaltyReceiver = _receiver;
        royaltyBps = _royaltyBps;
    }

    function _setRoyaltyBps(uint256 _royaltyBps) internal {
        require(_royaltyBps <= 10_000, "exceed royalty bps");
        royaltyBps = uint96(_royaltyBps);
        emit RoyaltyUpdated(royaltyBps);
    }

    function getTokenRoyaltyRecipient(uint256) internal view virtual returns (address tokenRoyaltyReceiver) {
        tokenRoyaltyReceiver = royaltyReceiver;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = getTokenRoyaltyRecipient(tokenId);
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }
}
