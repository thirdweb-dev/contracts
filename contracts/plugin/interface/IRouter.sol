// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

interface IRouter {
    fallback() external payable;

    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address);
}
