// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextConsumer {
    function _msgSender() public view virtual returns (address sender) {
        try IERC2771Context(address(this)).isTrustedForwarder(msg.sender) returns (bool success) {
            if (success) {
                // The assembly code is more direct than the Solidity version using `abi.decode`.
                assembly {
                    sender := shr(96, calldataload(sub(calldatasize(), 20)))
                }

                return sender;
            }
        } catch {}

        return msg.sender;
    }

    function _msgData() public view virtual returns (bytes calldata) {
        try IERC2771Context(address(this)).isTrustedForwarder(msg.sender) returns (bool success) {
            if (success) {
                return msg.data[:msg.data.length - 20];
            }
        } catch {}

        return msg.data;
    }
}
