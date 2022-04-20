// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
 * @dev Mock contract for typechain types generation purposes :)
 */
contract Mock {
    IERC20 public erc20;
    IERC721 public erc721;
    IERC1155 public erc1155;
}

contract MockContract {
    bytes32 private name;
    uint8 private version;

    constructor(bytes32 _name, uint8 _version) {
        name = _name;
        version = _version;
    }

    /// @dev Returns the module type of the contract.
    function contractType() external view returns (bytes32) {
        return name;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external view returns (uint8) {
        return version;
    }
}
