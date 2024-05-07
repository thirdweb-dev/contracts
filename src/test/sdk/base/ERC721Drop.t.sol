// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721Drop } from "contracts/base/ERC721Drop.sol";

contract BaseERC721DropTest is BaseUtilTest {
    ERC721Drop internal base;
    using Strings for uint256;

    address recipient;

    function setUp() public override {
        super.setUp();

        recipient = address(0x123);

        vm.prank(signer);
        base = new ERC721Drop(signer, NAME, SYMBOL, royaltyRecipient, royaltyBps, saleRecipient);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `claim`
    //////////////////////////////////////////////////////////////*/

    function test_state_claim_ZeroPrice() public {
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        string memory _baseURI = "baseURI/";
        uint256 _quantity = 10;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(receiver);

        bytes32[] memory proofs = new bytes32[](0);

        ERC721Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC721Drop.ClaimCondition[] memory conditions = new ERC721Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        base.claim(receiver, _quantity, address(0), 0, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(receiver), currentBalanceOfRecipient + _quantity);

        for (uint256 i = 0; i < _quantity; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURI, i.toString())));
            assertEq(base.ownerOf(i), receiver);
        }
    }

    function test_state_claim_NonZeroPrice_ERC20() public {
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        string memory _baseURI = "baseURI/";
        uint256 _quantity = 10;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(receiver);

        bytes32[] memory proofs = new bytes32[](0);

        ERC721Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC721Drop.ClaimCondition[] memory conditions = new ERC721Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        // set price and currency
        conditions[0].pricePerToken = 1;
        conditions[0].currency = address(erc20);

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        // mint erc20 to claimer, and approve to base
        erc20.mint(claimer, 1_000);
        vm.prank(claimer);
        erc20.approve(address(base), 10);

        vm.prank(claimer, claimer);
        base.claim(receiver, _quantity, address(erc20), 1, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(receiver), currentBalanceOfRecipient + _quantity);

        for (uint256 i = 0; i < _quantity; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURI, i.toString())));
            assertEq(base.ownerOf(i), receiver);
        }
    }

    function test_state_claim_NonZeroPrice_NativeToken() public {
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        string memory _baseURI = "baseURI/";
        uint256 _quantity = 10;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(receiver);

        bytes32[] memory proofs = new bytes32[](0);

        ERC721Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC721Drop.ClaimCondition[] memory conditions = new ERC721Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        // set price and currency
        conditions[0].pricePerToken = 1;
        conditions[0].currency = address(NATIVE_TOKEN);

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        // deal NATIVE_TOKEN to claimer
        vm.deal(claimer, 1_000);

        vm.prank(claimer, claimer);
        base.claim{ value: 10 }(receiver, _quantity, address(NATIVE_TOKEN), 1, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(receiver), currentBalanceOfRecipient + _quantity);

        for (uint256 i = 0; i < _quantity; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURI, i.toString())));
            assertEq(base.ownerOf(i), receiver);
        }
    }

    function test_revert_claim_NotEnoughMintedTokens() public {
        vm.warp(1);

        address receiver = address(0x123);
        address claimer = address(0x345);
        string memory _baseURI = "baseURI/";
        uint256 _quantity = 10;

        bytes32[] memory proofs = new bytes32[](0);

        ERC721Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC721Drop.ClaimCondition[] memory conditions = new ERC721Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerWallet = 100;

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        vm.expectRevert("Not enough minted tokens");
        vm.prank(claimer, claimer);
        base.claim(receiver, _quantity + 1000, address(0), 0, alp, "");
    }
}
