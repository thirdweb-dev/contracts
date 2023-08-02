// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../marketplace/direct-listings/DirectListingsLogic.sol";

contract BaseMartLogic is DirectListingsLogic {
    constructor(address _nativeTokenWrapper) DirectListingsLogic(_nativeTokenWrapper) {}
}
