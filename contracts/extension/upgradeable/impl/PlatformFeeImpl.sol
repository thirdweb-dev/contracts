// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../PlatformFee.sol";

import "../../interface/IPermissions.sol";
import "../../interface/IERC2771Context.sol";

contract PlatformFeeImpl is PlatformFee {
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;

    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return IPermissions(address(this)).hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _msgSender() internal view returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
