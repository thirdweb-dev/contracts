// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../interfaces/IThirdwebRoyalty.sol";

abstract contract ThirdwebRoyalty is IThirdwebRoyalty {
    uint256 internal constant ROYALTY_FEE_TYPE = 1;
}