// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { SignatureActionStorage } from "../extension/SignatureActionUpgradeable.sol";
import { EIP712Storage } from "../extension/EIP712Upgradeable.sol";
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

contract SignatureActionInit is EIP712Init {
    function __SignatureAction_init() internal onlyInitializing {
        __EIP712_init("SignatureAction", "1");
    }
}
