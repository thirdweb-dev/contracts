// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../mocks/MockERC20.sol";

contract MockLink is MockERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata
    ) external returns (bool) {
        super.transfer(to, value);
    }
}

contract VRFV2Wrapper {
    uint256 private nextId = 5;

    function lastRequestId() external view returns (uint256 id) {
        id = nextId;
    }

    function calculateRequestPrice(uint32 _callbackGasLimit) external pure returns (uint256) {
        return _callbackGasLimit;
    }
}
