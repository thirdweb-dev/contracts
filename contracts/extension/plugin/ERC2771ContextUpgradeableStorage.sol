// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library ERC2771ContextUpgradeableStorage {
    bytes32 public constant ERC2771_CONTEXT_UPGRADEABLE_STORAGE_POSITION =
        keccak256("erc2771.context.upgradeable.storage");

    struct Data {
        mapping(address => bool) _trustedForwarder;
    }

    function erc2771ContextUpgradeableStorage() internal pure returns (Data storage erc2771ContextData) {
        bytes32 position = ERC2771_CONTEXT_UPGRADEABLE_STORAGE_POSITION;
        assembly {
            erc2771ContextData.slot := position
        }
    }
}
