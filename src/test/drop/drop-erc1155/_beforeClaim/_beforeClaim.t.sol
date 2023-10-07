// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC1155, IPermissions, ILazyMint } from "contracts/prebuilts/drop/DropERC1155.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HarnessDropERC1155 is DropERC1155 {
    function beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata alp,
        bytes memory
    ) external view {
        _beforeClaim(_tokenId, address(0), _quantity, address(0), 0, alp, bytes(""));
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

contract DropERC1155Test_beforeClaim is BaseTest {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);
    event TokenURIRevealed(uint256 indexed index, string revealedURI);
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

    HarnessDropERC1155 public drop;

    bytes private emptyEncodedBytes = abi.encode("", "");

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
        drop.setMaxTotalSupply(0, 1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: misc.
    //////////////////////////////////////////////////////////////*/

    /**
     *  note: Tests whether contract reverts when a non-holder renounces a role.
     */
    function test_revert_ExceedMaxSupply() public {
        DropERC1155.AllowlistProof memory alp;
        vm.expectRevert("exceed max total supply");
        drop.beforeClaim(0, address(0), 2, address(0), 0, alp, bytes(""));
    }

    function test_NoRevert() public view {
        DropERC1155.AllowlistProof memory alp;
        drop.beforeClaim(0, address(0), 1, address(0), 0, alp, bytes(""));
    }
}
