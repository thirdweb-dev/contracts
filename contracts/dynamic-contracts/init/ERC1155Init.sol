// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC1155Storage } from "../eip/ERC1155Upgradeable.sol";
import "../extension/Initializable.sol";

contract ERC1155Init is Initializable {
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        ERC1155Storage.Data storage erc1155data = ERC1155Storage.erc1155Storage();

        erc1155data._uri = uri_;
    }
}
