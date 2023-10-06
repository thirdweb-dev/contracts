// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract HarnessDropERC721 is DropERC721 {
    function transferTokensOnClaim(address _to, uint256 _quantityToClaim) public payable {
        _transferTokensOnClaim(_to, _quantityToClaim);
    }

    function initializeHarness(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _metadataRole = keccak256("METADATA_ROLE");

        // Initialize inherited contracts, most base-like -> most derived.
        // __ERC2771Context_init(_trustedForwarders);
        // __ERC721A_init(_name, _symbol);

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

contract DropERC721Test_transferTokensOnClaim is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC721 public dropImp;

    address private transferTokens_saleRecipient = address(0x010);
    address private transferTokens_royaltyRecipient = address(0x011);
    uint128 private transferTokens_royaltyBps = 1000;
    uint128 private transferTokens_platformFeeBps = 1000;
    address private transferTokens_platformFeeRecipient = address(0x012);
    uint256 private transferTokens_quantityToClaim = 1;
    address private transferTokens_receiver;

    ERC20 private nonReceiver;

    function setUp() public override {
        super.setUp();

        dropImp = new HarnessDropERC721();
        dropImp.initializeHarness(
            deployer,
            NAME,
            SYMBOL,
            CONTRACT_URI,
            forwarders(),
            transferTokens_saleRecipient,
            transferTokens_royaltyRecipient,
            transferTokens_royaltyBps,
            transferTokens_platformFeeBps,
            transferTokens_platformFeeRecipient
        );

        nonReceiver = new ERC20("", "");
    }

    modifier transferToEOA() {
        transferTokens_receiver = address(0x111);
        _;
    }

    modifier transferToNonReceiver() {
        transferTokens_receiver = address(nonReceiver);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    function test_revert_transferToNonReceiver() public transferToNonReceiver {
        vm.expectRevert(IERC721AUpgradeable.TransferToNonERC721ReceiverImplementer.selector);
        dropImp.transferTokensOnClaim(transferTokens_receiver, 1);
    }

    function test_transferToEOA() public transferToEOA {
        uint256 eoaBalanceBefore = dropImp.balanceOf(transferTokens_receiver);
        uint256 supplyBefore = dropImp.totalSupply();
        dropImp.transferTokensOnClaim(transferTokens_receiver, 1);
        assertEq(dropImp.totalSupply(), supplyBefore + 1);
        assertEq(dropImp.balanceOf(transferTokens_receiver), eoaBalanceBefore + 1);
    }
}
