// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Context.sol";

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

abstract contract ERC2771Context is Context {
    constructor(address[] memory trustedForwarder) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();

        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            data.trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();
        return data.trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    uint256[49] private __gap;
}
