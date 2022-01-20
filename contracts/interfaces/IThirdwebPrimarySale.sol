// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IThirdwebNFT.sol";

interface IThirdwebPrimarySale is IThirdwebToken {

    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev The adress that receives all primary sales value.
    function platformFeeRecipient() external view returns (address);

    /// @dev The % of primary sales collected by the contract as fees.
    function platformFeeBps() external view returns (uint256);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;
}