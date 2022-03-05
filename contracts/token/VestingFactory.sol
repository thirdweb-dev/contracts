// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./VestingBase.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

///@title Creates vesting contracts based on `VestingBase` implementation
contract VestingFactory {
    address private immutable baseImplementation;
    event VestingWalletCreated(address indexed beneficiaryAddress, uint64 startTimestamp, uint64 durationSeconds, address indexed vestingWalletAddress);

    constructor () {
        baseImplementation = address(new VestingBase());
    }

    /// @dev The newly created wallet should have zero balance
    function createVestingSchedule(       
        address _beneficiaryAddress,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) external returns (address) {
        address clone = Clones.clone(baseImplementation);
        VestingBase(payable(clone)).initialize(
            _beneficiaryAddress,
            _startTimestamp,
            _durationSeconds
        );
        emit VestingWalletCreated(_beneficiaryAddress, _startTimestamp, _durationSeconds, clone);
        return clone;
    }
}