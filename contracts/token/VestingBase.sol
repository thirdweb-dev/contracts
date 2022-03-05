// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

/** 
    * @title Provides a base implementation of the vesting wallet to be used by `VestingFactory`
*/
contract VestingBase is VestingWalletUpgradeable {

    constructor() initializer {return;}

    function initialize(
        address _beneficiaryAddress,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) public initializer {
        __VestingWallet_init(
            _beneficiaryAddress,
            _startTimestamp,
            _durationSeconds
        );
    }
}