// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { EIP712Storage } from "../eip/draft-EIP712Upgradeable.sol";
import "../extension/Initializable.sol";

contract EIP712Init is Initializable {
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));

        EIP712Storage.Data storage data = EIP712Storage.eip712Storage();
        data._HASHED_NAME = hashedName;
        data._HASHED_VERSION = hashedVersion;
    }
}
