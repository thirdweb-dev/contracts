// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC721Drop } from "contracts/base/ERC721Drop.sol";

contract BaseERC721ERC721DropTest is BaseUtilTest {
    ERC721Drop internal base;
    using TWStrings for uint256;

    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    ERC721Drop.MintRequest _mintrequest;
    bytes _signature;

    address recipient;

    function setUp() public override {
        super.setUp();

        recipient = address(0x123);

        vm.prank(signer);
        base = new ERC721Drop(NAME, SYMBOL, royaltyRecipient, royaltyBps, saleRecipient);

        typehashMintRequest = keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC721"));
        versionHash = keccak256(bytes("1"));
        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        domainSeparator = keccak256(abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(base)));

        _mintrequest.to = recipient;
        _mintrequest.royaltyRecipient = royaltyRecipient;
        _mintrequest.royaltyBps = royaltyBps;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.uri = "ipfs://";
        _mintrequest.quantity = 1;
        _mintrequest.pricePerToken = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(ERC721Drop.MintRequest memory _request, uint256 _privateKey)
        internal
        returns (bytes memory)
    {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            keccak256(bytes(_request.uri)),
            _request.quantity,
            _request.pricePerToken,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

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

    function test_revert_claim_BOT() public {
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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        bytes memory revertMsg = "BOT";
        vm.expectRevert(revertMsg);
        vm.prank(claimer);
        base.claim(receiver, _quantity, address(0), 0, alp, "");
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
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        vm.expectRevert("Not enough minted tokens");
        vm.prank(claimer, claimer);
        base.claim(receiver, _quantity + 1000, address(0), 0, alp, "");
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);
        string memory _baseURI = "baseURI/";

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        base.mintWithSignature(_mintrequest, _signature);

        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);

        for (uint256 i = 0; i < _mintrequest.quantity; i += 1) {
            string memory _tokenURI = base.tokenURI(i);
            assertEq(_tokenURI, string(abi.encodePacked(_baseURI, i.toString())));
            assertEq(base.ownerOf(i), recipient);
        }
    }

    function test_revert_mintWithSignature_NotEnoughTokens() public {
        vm.warp(1000);
        string memory _baseURI = "baseURI/";

        vm.prank(signer);
        base.lazyMint(100, _baseURI, "");

        _mintrequest.quantity = 101;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("Not enough lazy minted tokens.");
        base.mintWithSignature(_mintrequest, _signature);
    }
}
