// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import "../../../utils/BaseTest.sol";
import "../../../../../lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC2981Upgradeable.sol";

contract DropERC721Test_misc is BaseTest {
    DropERC721 public drop;

    bytes private misc_data;
    string private misc_baseURI;
    uint256 private misc_amount;
    bytes private misc_encryptedURI;
    bytes32 private misc_provenanceHash;
    string private misc_revealedURI;
    uint256 private misc_index;
    bytes private misc_key;
    address private unauthorized = address(0x123);

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier callerNotApproved() {
        vm.startPrank(unauthorized);
        _;
    }

    modifier callerOwner() {
        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        vm.startPrank(receiver);
        _;
    }

    modifier callerApproved() {
        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);
        vm.prank(receiver);
        drop.setApprovalForAll(deployer, true);
        vm.startPrank(deployer);
        _;
    }

    modifier validIndex() {
        misc_index = 0;
        _;
    }

    modifier invalidKey() {
        misc_key = "invalidKey";
        _;
    }

    modifier lazyMintEncrypted() {
        misc_amount = 10;
        misc_baseURI = "ipfs://";
        misc_revealedURI = "ipfs://revealed";
        misc_key = "key";
        misc_encryptedURI = drop.encryptDecrypt(bytes(misc_revealedURI), misc_key);
        misc_provenanceHash = keccak256(abi.encodePacked(misc_revealedURI, misc_key, block.chainid));
        misc_data = abi.encode(misc_encryptedURI, misc_provenanceHash);
        vm.prank(deployer);
        drop.lazyMint(misc_amount, misc_baseURI, misc_data);
        _;
    }

    modifier tokenClaimed() {
        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "0";
        inputs[4] = Strings.toHexString(uint160(address(erc20))); // address of erc20

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        DropERC721.AllowlistProof memory alp;
        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        address receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd); // in allowlist

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);

        // vm.prank(getActor(5), getActor(5));
        vm.prank(receiver, receiver);
        drop.claim(receiver, 10, address(erc20), 0, alp, ""); // claims for free, because allowlist price is 0
        _;
    }

    function test_totalMinted_TenLazyMintedZeroClaim() public lazyMintEncrypted {
        uint256 totalMinted = drop.totalMinted();
        assertEq(totalMinted, 0);
    }

    function test_totalMinted_TenLazyMintedTenClaim() public lazyMintEncrypted tokenClaimed {
        uint256 totalMinted = drop.totalMinted();
        assertEq(totalMinted, 10);
    }

    function test_nextTokenIdToMint_ZeroLazyMinted() public {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 0);
    }

    function test_nextTokenIdToMint_TenLazyMinted() public lazyMintEncrypted {
        uint256 nextTokenIdToMint = drop.nextTokenIdToMint();
        assertEq(nextTokenIdToMint, 10);
    }

    function test_nextTokenIdToClaim_ZeroClaimed() public {
        uint256 nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(nextTokenIdToClaim, 0);
    }

    function test_nextTokenIdToClaim_TenClaimed() public lazyMintEncrypted tokenClaimed {
        uint256 nextTokenIdToClaim = drop.nextTokenIdToClaim();
        assertEq(nextTokenIdToClaim, 10);
    }

    function test_burn_revert_callerNotApproved() public lazyMintEncrypted tokenClaimed callerNotApproved {
        vm.expectRevert(IERC721AUpgradeable.TransferCallerNotOwnerNorApproved.selector);
        drop.burn(0);
    }

    function test_burn_CallerApproved() public lazyMintEncrypted tokenClaimed callerApproved {
        drop.burn(0);
        uint256 totalSupply = drop.totalSupply();
        assertEq(totalSupply, 9);
        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        drop.ownerOf(0);
    }

    function test_burn_revert_callerOwnerOfToken() public lazyMintEncrypted tokenClaimed callerOwner {
        drop.burn(0);
        uint256 totalSupply = drop.totalSupply();
        assertEq(totalSupply, 9);
        vm.expectRevert(IERC721AUpgradeable.OwnerQueryForNonexistentToken.selector);
        drop.ownerOf(0);
    }

    function test_contractType() public {
        assertEq(drop.contractType(), bytes32("DropERC721"));
    }

    function test_contractVersion() public {
        assertEq(drop.contractVersion(), uint8(4));
    }

    function test_supportsInterface() public {
        assertEq(drop.supportsInterface(type(IERC2981Upgradeable).interfaceId), true);
        assertEq(drop.supportsInterface(type(IERC721Upgradeable).interfaceId), true);
        assertEq(drop.supportsInterface(type(IERC721MetadataUpgradeable).interfaceId), true);
    }

    function test__msgData() public {
        HarnessDropERC721MsgData msgDataDrop = new HarnessDropERC721MsgData();
        bytes memory msgData = msgDataDrop.msgData();
        bytes4 expectedData = msgDataDrop.msgData.selector;
        assertEq(bytes4(msgData), expectedData);
    }
}

contract HarnessDropERC721MsgData is DropERC721 {
    function msgData() public view returns (bytes memory) {
        return _msgData();
    }
}
