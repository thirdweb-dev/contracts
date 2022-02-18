// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface IThirdwebPrimarySale {
    /// @dev The adress that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;
}
