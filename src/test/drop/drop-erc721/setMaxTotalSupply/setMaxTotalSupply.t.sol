// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, IDelayedReveal, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DropERC721Test_setMaxTotalSupply is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    DropERC721 public drop;

    bytes private maxsupply_data;
    string private maxsupply_baseURI;
    uint256 private maxsupply_amount;
    bytes private maxsupply_encryptedURI;
    bytes32 private maxsupply_provenanceHash;
    string private maxsupply_revealedURI;
    uint256 private maxsupply_index;
    bytes private maxsupply_key;
    address private unauthorized = address(0x123);

    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));

        erc20.mint(deployer, 1_000 ether);
        vm.deal(deployer, 1_000 ether);
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerNotAdmin() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerAdmin() {
        vm.startPrank(deployer);
        _;
    }

    function test_revert_CallerNotAdmin() public callerNotAdmin {
        bytes32 role = bytes32(0x00);
        vm.expectRevert(
            abi.encodePacked(
                "Permissions: account ",
                TWStrings.toHexString(uint160(unauthorized), 20),
                " is missing role ",
                TWStrings.toHexString(uint256(role), 32)
            )
        );
        drop.setMaxTotalSupply(0);
    }

    function test_state() public callerAdmin {
        drop.setMaxTotalSupply(0);
        assertEq(drop.maxTotalSupply(), 0);
    }

    function test_event() public callerAdmin {
        vm.expectEmit(false, false, false, false);
        emit MaxTotalSupplyUpdated(0);
        drop.setMaxTotalSupply(0);
    }
}
