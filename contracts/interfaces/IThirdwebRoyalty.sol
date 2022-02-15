// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IThirdwebRoyalty is IERC2981 {
    /// @dev Returns the royalty recipient and fee bps.
    function getRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyRecipientForToken(uint256 tokenId, address recipient) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyRecipientForToken(uint256 tokenId) external view returns (address);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyUpdated(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyRecipient(uint256 indexed tokenId, address royaltyRecipient);
}
