// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../eip/queryable/ERC721AStorage.sol";
import "../../../eip/queryable/ERC721A__Initializable.sol";

contract ERC721AQueryableInit is ERC721A__Initializable {
    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
        ERC721AStorage.layout()._currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }
}
