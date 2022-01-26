// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebModule.sol";

// Helper interfaces
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IThirdwebRoyalty is IThirdwebModule, IERC2981 {
    /// @dev The recipient of who gets the royalty.
    function royaltyRecipient() external view returns (address);

    /// @dev The percentage of royalty how much royalty in basis points.
    function royaltyBps() external view returns (uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setRoyaltyInfo(address _royaltyRecipient, uint16 _royaltyBps) external;
}
