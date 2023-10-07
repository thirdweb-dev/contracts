// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
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

contract DropERC1155Test_beforeTokenTransfer is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    HarnessDropERC1155 public drop;

    address private beforeTransfer_from = address(0x01);
    address private beforeTransfer_to = address(0x01);
    uint256[] private beforeTransfer_ids;
    uint256[] private beforeTransfer_amounts;
    bytes private beforeTransfer_data;

    using stdStorage for StdStorage;

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

        beforeTransfer_ids = new uint256[](1);
        beforeTransfer_ids[0] = 0;
        beforeTransfer_amounts = new uint256[](1);
        beforeTransfer_amounts[0] = 1;
        beforeTransfer_data = abi.encode("", "");
    }

    modifier fromAddressZero() {
        beforeTransfer_from = address(0);
        _;
    }

    modifier toAddressZero() {
        beforeTransfer_to = address(0);
        _;
    }

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_state_transferFromZero() public fromAddressZero {
        uint256 beforeTokenTotalSupply = drop.totalSupply(0);
        drop.beforeTokenTransfer(
            deployer,
            beforeTransfer_from,
            beforeTransfer_to,
            beforeTransfer_ids,
            beforeTransfer_amounts,
            beforeTransfer_data
        );
        uint256 afterTokenTotalSupply = drop.totalSupply(0);
        assertEq(beforeTokenTotalSupply + beforeTransfer_amounts[0], afterTokenTotalSupply);
    }

    function test_state_tranferToZero() public toAddressZero {
        drop.beforeTokenTransfer(deployer, beforeTransfer_to, beforeTransfer_from, beforeTransfer_ids, beforeTransfer_amounts, beforeTransfer_data);
        uint256 beforeTokenTotalSupply = drop.totalSupply(0);
        drop.beforeTokenTransfer(
            deployer,
            beforeTransfer_from,
            beforeTransfer_to,
            beforeTransfer_ids,
            beforeTransfer_amounts,
            beforeTransfer_data
        );
        uint256 afterTokenTotalSupply = drop.totalSupply(0);
        assertEq(beforeTokenTotalSupply - beforeTransfer_amounts[0], afterTokenTotalSupply);
    }
}
