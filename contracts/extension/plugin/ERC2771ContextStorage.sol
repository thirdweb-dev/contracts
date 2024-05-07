// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

library ERC2771ContextStorage {
    /// @custom:storage-location erc7201:erc2771.context.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("erc2771.context.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION =
        0x82aadcdf5bea62fd30615b6c0754b644e71b6c1e8c55b71bb927ad005b504f00;

    struct Data {
        mapping(address => bool) _trustedForwarder;
    }

    function erc2771ContextStorage() internal pure returns (Data storage erc2771ContextData) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            erc2771ContextData.slot := position
        }
    }
}
