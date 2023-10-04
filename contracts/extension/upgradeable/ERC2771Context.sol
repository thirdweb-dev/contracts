// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../interface/IERC2771Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */

library ERC2771ContextStorage {
    /// @custom:storage-location erc7201:erc2771.context.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("erc2771.context.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION =
        0x82aadcdf5bea62fd30615b6c0754b644e71b6c1e8c55b71bb927ad005b504f00;

    struct Data {
        mapping(address => bool) trustedForwarder;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract ERC2771Context is IERC2771Context {
    constructor(address[] memory trustedForwarder) {
        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            _erc2771ContextStorage().trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _erc2771ContextStorage().trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /// @dev Returns the ERC2771ContextStorage storage.
    function _erc2771ContextStorage() internal pure returns (ERC2771ContextStorage.Data storage data) {
        data = ERC2771ContextStorage.data();
    }

    uint256[49] private __gap;
}
