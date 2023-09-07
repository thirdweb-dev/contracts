// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Context variant with ERC2771 support.
 */

library ERC2771ContextStorage {
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION = keccak256("erc2771.context.storage");

    struct Data {
        mapping(address => bool) trustedForwarder;
    }

    function erc2771ContextStorage() internal pure returns (Data storage erc2771ContextData) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            erc2771ContextData.slot := position
        }
    }
}

contract ERC2771ContextExt {
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();
        return data.trustedForwarder[forwarder];
    }
}
