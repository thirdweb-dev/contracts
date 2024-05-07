// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./ERC2771ContextLogic.sol";

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextConsumer {
    function _msgSender() public view virtual returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() public view virtual returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
