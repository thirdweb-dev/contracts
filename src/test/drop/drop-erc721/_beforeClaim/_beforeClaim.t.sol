// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC721 } from "contracts/prebuilts/drop/DropERC721.sol";

// Test imports
import "../../../utils/BaseTest.sol";

contract DropERC721Test_beforeClaim is BaseTest {
    event TokenURIRevealed(uint256 indexed index, string revealedURI);

    DropERC721 public drop;

    bytes private beforeClaim_data;
    string private beforeClaim_baseURI;
    uint256 private beforeClaim_amount;
    address private receiver = address(0xDDdDddDdDdddDDddDDddDDDDdDdDDdDDdDDDDDDd);

    DropERC721.AllowlistProof private alp;

    function setUp() public override {
        super.setUp();
        drop = DropERC721(getContract("DropERC721"));

        string[] memory inputs = new string[](5);

        inputs[0] = "node";
        inputs[1] = "src/test/scripts/generateRoot.ts";
        inputs[2] = "300";
        inputs[3] = "0";
        inputs[4] = Strings.toHexString(uint160(address(erc20)));

        bytes memory result = vm.ffi(inputs);
        // revert();
        bytes32 root = abi.decode(result, (bytes32));

        inputs[1] = "src/test/scripts/getProof.ts";
        result = vm.ffi(inputs);
        bytes32[] memory proofs = abi.decode(result, (bytes32[]));

        alp.proof = proofs;
        alp.quantityLimitPerWallet = 300;
        alp.pricePerToken = 0;
        alp.currency = address(erc20);

        vm.warp(1);

        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 500;
        conditions[0].quantityLimitPerWallet = 10;
        conditions[0].merkleRoot = root;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = address(erc20);

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);
    }

    /*///////////////////////////////////////////////////////////////
                        Branch Testing
    //////////////////////////////////////////////////////////////*/

    modifier lazyMintUnEncrypted() {
        beforeClaim_amount = 10;
        beforeClaim_baseURI = "ipfs://";
        vm.prank(deployer);
        drop.lazyMint(beforeClaim_amount, beforeClaim_baseURI, beforeClaim_data);
        _;
    }

    modifier setMaxSupply() {
        vm.prank(deployer);
        drop.setMaxTotalSupply(5);
        _;
    }

    function test_revert_greaterThanNextTokenIdToLazyMint() public lazyMintUnEncrypted {
        vm.prank(receiver, receiver);
        vm.expectRevert("!Tokens");
        drop.claim(receiver, 11, address(erc20), 0, alp, "");
    }

    function test_revert_greaterThanMaxTotalSupply() public lazyMintUnEncrypted setMaxSupply {
        vm.prank(receiver, receiver);
        vm.expectRevert("!Supply");
        drop.claim(receiver, 6, address(erc20), 0, alp, "");
    }
}
