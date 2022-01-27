// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebModule.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IThirdwebRoyalty is IERC2981, IThirdwebModule {
    /// @dev The thirdweb contract with fee related information.
    function thirdwebFees() external view returns (address);

    /// @dev Returns the platform fee bps and recipient.
    function getRoyaltyFeeInfo() external returns (address recipient, uint16 royaltyFeeBps);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Distributes accrued royalty and thirdweb fees (% of the accrued royalty) to the relevant stakeholders.
    function withdrawFunds(address _currency) external;
}
