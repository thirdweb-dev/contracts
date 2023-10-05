// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721, IDelayedReveal, ERC721AUpgradeable, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract DropERC721Test_canSetFunctions is BaseTest {
    using StringsUpgradeable for uint256;

    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    DropERC721 public drop;

    bytes private canset_data;
    string private canset_baseURI;
    uint256 private canset_amount;
    bytes private canset_encryptedURI;
    bytes32 private canset_provenanceHash;
    string private canset_revealedURI;
    uint256 private canset_index;
    bytes private canset_key;
    address private unauthorized = address(0x123);

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
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

    modifier callerNotMinter() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerMinter() {
        vm.startPrank(deployer);
        _;
    }

    function test__canSetPlatformFeeInfo_revert_callerNotAdmin() public callerNotAdmin {
        vm.expectRevert("Not authorized");
        drop.setPlatformFeeInfo(address(0x1), 1);
    }

    function test__canSetPlatformFeeInfo_callerAdmin() public callerAdmin {
        drop.setPlatformFeeInfo(address(0x1), 1);
        (address recipient, uint16 bps) = drop.getPlatformFeeInfo();
        assertEq(recipient, address(0x1));
        assertEq(bps, 1);
    }

    function test__canSetPrimarySaleRecipient_revert_callerNotAdmin() public callerNotAdmin {
        vm.expectRevert("Not authorized");
        drop.setPrimarySaleRecipient(address(0x1));
    }

    function test__canSetPrimarySaleRecipient_callerAdmin() public callerAdmin {
        drop.setPrimarySaleRecipient(address(0x1));
        assertEq(drop.primarySaleRecipient(), address(0x1));
    }

    function test__canSetOwner_revert_callerNotAdmin() public callerNotAdmin {
        vm.expectRevert("Not authorized");
        drop.setOwner(address(0x1));
    }

    function test__canSetOwner_callerAdmin() public callerAdmin {
        drop.setOwner(address(0x1));
        assertEq(drop.owner(), address(0x1));
    }

    function test__canSetRoyaltyInfo_revert_callerNotAdmin() public callerNotAdmin {
        vm.expectRevert("Not authorized");
        drop.setDefaultRoyaltyInfo(address(0x1), 1);
    }

    function test__canSetRoyaltyInfo_callerAdmin() public callerAdmin {
        drop.setDefaultRoyaltyInfo(address(0x1), 1);
        (address recipient, uint16 bps) = drop.getDefaultRoyaltyInfo();
        assertEq(recipient, address(0x1));
        assertEq(bps, 1);
    }

    function test__canSetContractURI_revert_callerNotAdmin() public callerNotAdmin {
        vm.expectRevert("Not authorized");
        drop.setContractURI("ipfs://");
    }

    function test__canSetContractURI_callerAdmin() public callerAdmin {
        drop.setContractURI("ipfs://");
        assertEq(drop.contractURI(), "ipfs://");
    }

    function test__canSetClaimConditions_revert_callerNotAdmin() public callerNotAdmin {
        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = bytes32(0);
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(0x111);
        vm.expectRevert("Not authorized");
        drop.setClaimConditions(conditions, true);
    }

    function test__canSetClaimConditions_callerAdmin() public callerAdmin {
        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = bytes32(0);
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(0x111);
        drop.setClaimConditions(conditions, true);
    }

    function test__canLazyMint_revert_callerNotMinter() public callerNotMinter {
        canset_amount = 10;
        canset_baseURI = "ipfs://";
        canset_data = abi.encode(canset_encryptedURI, canset_provenanceHash);
        vm.expectRevert("Not authorized");
        drop.lazyMint(canset_amount, canset_baseURI, canset_data);
    }

    function test__canLazyMint_callerMinter() public callerMinter {
        canset_amount = 10;
        canset_baseURI = "ipfs://";
        canset_data = abi.encode(canset_encryptedURI, canset_provenanceHash);
        drop.lazyMint(canset_amount, canset_baseURI, canset_data);
    }
}
