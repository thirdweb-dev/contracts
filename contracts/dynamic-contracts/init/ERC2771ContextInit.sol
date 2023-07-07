// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC2771ContextStorage } from "../extension/ERC2771Context.sol";
import "../extension/Initializable.sol";

contract ERC2771ContextInit is Initializable {
    function __ERC2771Context_init(address[] memory trustedForwarder) internal onlyInitializing {
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address[] memory trustedForwarder) internal onlyInitializing {
        ERC2771ContextStorage.Data storage data = ERC2771ContextStorage.erc2771ContextStorage();

        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            data.trustedForwarder[trustedForwarder[i]] = true;
        }
    }
}
