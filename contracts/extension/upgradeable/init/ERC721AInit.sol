// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ERC721AStorage } from "../../../eip/ERC721AUpgradeable.sol";
import "../Initializable.sol";

contract ERC721AInit is Initializable {
    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();

        data._name = name_;
        data._symbol = symbol_;
        data._currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }
}
