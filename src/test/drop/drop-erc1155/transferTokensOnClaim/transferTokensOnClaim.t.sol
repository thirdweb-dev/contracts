// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function transferTokensOnClaimHarness(address to, uint256 _tokenId, uint256 _quantityBeingClaimed) external {
        transferTokensOnClaim(to, _tokenId, _quantityBeingClaimed);
    }

    function initializeHarness(
        address _defaultAdmin,
        string memory _contractURI,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _metadataRole = keccak256("METADATA_ROLE");

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        _setupRole(_metadataRole, _defaultAdmin);
        _setRoleAdmin(_metadataRole, _metadataRole);

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _setupPrimarySaleRecipient(_saleRecipient);
    }
}

contract MockERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract MockERC11555NotReceiver {}

contract DropERC1155Test_transferTokensOnClaim is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    HarnessDropERC1155 public drop;

    address private to;
    MockERC1155Receiver private receiver;
    MockERC11555NotReceiver private notReceiver;

    function setUp() public override {
        super.setUp();
        drop = new HarnessDropERC1155();
        drop.initializeHarness(
            address(this),
            "https://token-cdn-domain/{id}.json",
            deployer,
            deployer,
            1000,
            1000,
            deployer
        );
        receiver = new MockERC1155Receiver();
        notReceiver = new MockERC11555NotReceiver();
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    modifier toEOA() {
        to = address(0x01);
        _;
    }

    modifier toReceiever() {
        to = address(receiver);
        _;
    }

    modifier toNotReceiever() {
        to = address(notReceiver);
        _;
    }

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_revert_ContractNotERC155Receiver() public toNotReceiever {
        vm.expectRevert("ERC1155: transfer to non ERC1155Receiver implementer");
        drop.transferTokensOnClaimHarness(to, 0, 1);
    }

    function test_state_ContractERC1155Receiver() public toReceiever {
        uint256 beforeBalance = drop.balanceOf(to, 0);
        drop.transferTokensOnClaimHarness(to, 0, 1);
        uint256 afterBalance = drop.balanceOf(to, 0);
        assertEq(beforeBalance + 1, afterBalance);
    }

    function test_state_EOAReceiver() public toEOA {
        uint256 beforeBalance = drop.balanceOf(to, 0);
        drop.transferTokensOnClaimHarness(to, 0, 1);
        uint256 afterBalance = drop.balanceOf(to, 0);
        assertEq(beforeBalance + 1, afterBalance);
    }
}
