// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// CREATE2 -- contract deployment.
import "@openzeppelin/contracts/utils/Create2.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Protocol Components
import { NFT } from "./NFT.sol";
import { Pack } from "./Pack.sol";
import { Market } from "./Market.sol";

contract Registry is Ownable {}
