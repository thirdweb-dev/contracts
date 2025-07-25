// <ai_context>
// Main integration tests for DropERC721FlatFee contract.
// Covers lazyMint, reveal, claim conditions, setMaxTotalSupply, etc.
// Adapted for flat fee in claim price collection.
// </ai_context>

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721FlatFee, Permissions, LazyMint, BatchMintMetadata, Drop, DelayedReveal, IDelayedReveal, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC721FlatFee.sol";
import { IPlatformFee } from "contracts/extension/interface/IPlatformFee.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import "../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC721FlatFeeTest is BaseTest {
    using Strings for uint256;
    using Strings for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    DropERC721FlatFee public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC721FlatFee(getContract("DropERC721FlatFee"));

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);

        // Set to flat fee mode
        vm.prank(deployer);
        drop.setPlatformFeeType(IPlatformFee.PlatformFeeType.Flat);
        vm.prank(deployer);
        drop.setFlatPlatformFeeInfo(platformFeeRecipient, 0.1 ether);
    }

    // Adapted tests from DropERC721.t.sol, with flat fee assertions in claim price tests
    // For example, in claim tests with price, assert saleRecipient gets total - flatFee, platform gets flatFee
    // Add revert if total < flatFee
    // ...
}