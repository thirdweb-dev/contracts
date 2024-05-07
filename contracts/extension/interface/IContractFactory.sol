// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IContractFactory {
    /**
     *  @notice Deploys a proxy that points to that points to the given implementation.
     *
     *  @param implementation           Address of the implementation to point to.
     *
     *  @param data                     Additional data to pass to the proxy constructor or any other data useful during deployement.
     *  @param salt                     Salt to use for the deterministic address generation.
     */
    function deployProxyByImplementation(
        address implementation,
        bytes memory data,
        bytes32 salt
    ) external returns (address);
}
