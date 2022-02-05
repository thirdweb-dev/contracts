// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IThirdwebPrimarySale.sol";

abstract contract ThirdwebPrimarySale is IThirdwebPrimarySale {
    uint256 internal constant PRIMARY_SALE_FEE_TYPE = 1;
}