// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../../interface/IERC2771Context.sol";
import "../PermissionsEnumerable.sol";

contract PermissionsEnumerableImpl is PermissionsEnumerable {
    function _msgSender() internal view override returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
