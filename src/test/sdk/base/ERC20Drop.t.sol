// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC20Drop } from "contracts/base/ERC20Drop.sol";

contract BaseERC20DropTest is BaseUtilTest {
    ERC20Drop internal base;
    using TWStrings for uint256;

    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    // permit
    bytes32 internal permitTypeHash;
    bytes32 internal permitNameHash;
    bytes32 internal permitVersionHash;

    // sigmint
    bytes32 internal typehashMintRequest;
    bytes32 internal nameHash;
    bytes32 internal versionHash;

    ERC20Drop.MintRequest _mintrequest;
    bytes _signature;

    uint256 public recipientPrivateKey = 5678;
    address public recipient;

    function setUp() public override {
        super.setUp();
        vm.prank(signer);
        base = new ERC20Drop(NAME, SYMBOL, CONTRACT_URI, saleRecipient);

        recipient = vm.addr(recipientPrivateKey);
        erc20.mint(recipient, 1_000_000 ether);
        vm.deal(recipient, 1_000_000 ether);

        typehashEip712 = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        // permit related inputs
        permitTypeHash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        permitNameHash = keccak256(bytes(NAME));
        permitVersionHash = keccak256("1");

        // signature mint inputs
        typehashMintRequest = keccak256(
            "MintRequest(address to,address primarySaleRecipient,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );
        nameHash = keccak256(bytes("SignatureMintERC20"));
        versionHash = keccak256(bytes("1"));

        _mintrequest.to = recipient;
        _mintrequest.primarySaleRecipient = saleRecipient;
        _mintrequest.quantity = 100 ether;
        _mintrequest.pricePerToken = 0;
        _mintrequest.currency = address(0);
        _mintrequest.validityStartTimestamp = 1000;
        _mintrequest.validityEndTimestamp = 2000;
        _mintrequest.uid = bytes32(0);

        _signature = signMintRequest(_mintrequest, privateKey);
    }

    function signMintRequest(ERC20Drop.MintRequest memory _request, uint256 _privateKey)
        internal
        returns (bytes memory)
    {
        bytes memory encodedRequest = abi.encode(
            typehashMintRequest,
            _request.to,
            _request.primarySaleRecipient,
            _request.quantity,
            _request.pricePerToken,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
        );
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 domainSeparator = keccak256(
            abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(base))
        );
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

        address claimer = address(0x345);
        uint256 _quantity = 10;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        bytes32[] memory proofs = new bytes32[](0);

        ERC20Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC20Drop.ClaimCondition[] memory conditions = new ERC20Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100;
        conditions[0].quantityLimitPerTransaction = 100;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        base.claim(recipient, _quantity, address(0), 0, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _quantity);
    }

    function test_state_claim_NonZeroPrice_ERC20() public {
        vm.warp(1);

        address claimer = address(0x345);
        uint256 _quantity = 10 ether;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        bytes32[] memory proofs = new bytes32[](0);

        ERC20Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC20Drop.ClaimCondition[] memory conditions = new ERC20Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100 ether;
        conditions[0].quantityLimitPerTransaction = 100 ether;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        // set price and currency
        conditions[0].pricePerToken = 1 ether;
        conditions[0].currency = address(erc20);

        uint256 totalPrice = (conditions[0].pricePerToken * _quantity) / 1 ether;

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        // mint erc20 to claimer, and approve to base
        erc20.mint(claimer, 1000 ether);
        vm.prank(claimer);
        erc20.approve(address(base), totalPrice);

        vm.prank(claimer, claimer);
        base.claim(recipient, _quantity, address(erc20), 1 ether, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _quantity);
    }

    function test_state_claim_NonZeroPrice_NativeToken() public {
        vm.warp(1);

        address claimer = address(0x345);
        uint256 _quantity = 10 ether;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        bytes32[] memory proofs = new bytes32[](0);

        ERC20Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC20Drop.ClaimCondition[] memory conditions = new ERC20Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100 ether;
        conditions[0].quantityLimitPerTransaction = 100 ether;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        // set price and currency
        conditions[0].pricePerToken = 1 ether;
        conditions[0].currency = address(NATIVE_TOKEN);

        uint256 totalPrice = (conditions[0].pricePerToken * _quantity) / 1 ether;

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        // deal NATIVE_TOKEN to claimer
        vm.deal(claimer, 1_000 ether);

        vm.prank(claimer, claimer);
        base.claim{ value: totalPrice }(recipient, _quantity, address(NATIVE_TOKEN), 1 ether, alp, "");

        assertEq(base.totalSupply(), currentTotalSupply + _quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _quantity);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `burn`
    //////////////////////////////////////////////////////////////*/

    function test_state_burn() public {
        address claimer = address(0x345);
        uint256 _quantity = 10 ether;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        bytes32[] memory proofs = new bytes32[](0);

        ERC20Drop.AllowlistProof memory alp;
        alp.proof = proofs;

        ERC20Drop.ClaimCondition[] memory conditions = new ERC20Drop.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = 100 ether;
        conditions[0].quantityLimitPerTransaction = 100 ether;
        conditions[0].waitTimeInSecondsBetweenClaims = type(uint256).max;

        vm.prank(signer);
        base.setClaimConditions(conditions[0], false);

        vm.prank(claimer, claimer);
        base.claim(recipient, _quantity, address(0), 0, alp, "");

        // burn minted tokens
        currentTotalSupply = base.totalSupply();
        currentBalanceOfRecipient = base.balanceOf(recipient);
        vm.prank(recipient);
        base.burn(_quantity);

        assertEq(base.totalSupply(), currentTotalSupply - _quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient - _quantity);
    }

    function test_revert_burn_NotEnoughBalance() public {
        vm.expectRevert("not enough balance");
        vm.prank(recipient);
        base.burn(1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `permit`
    //////////////////////////////////////////////////////////////*/

    function test_state_permit() public {
        // generate permit signature
        address _owner = recipient;
        address _spender = address(0x789);
        uint256 _value = 1 ether;
        uint256 _deadline = 1000;

        uint256 _nonce = base.nonces(_owner);

        domainSeparator = keccak256(
            abi.encode(typehashEip712, permitNameHash, permitVersionHash, block.chainid, address(base))
        );
        bytes32 structHash = keccak256(abi.encode(permitTypeHash, _owner, _spender, _value, _nonce, _deadline));
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(recipientPrivateKey, typedDataHash);

        // call permit to approve _value to _spender
        base.permit(_owner, _spender, _value, _deadline, v, r, s);

        // check allowance
        uint256 _allowance = base.allowance(_owner, _spender);

        assertEq(_allowance, _value);
        assertEq(base.nonces(_owner), _nonce + 1);
    }

    function test_revert_permit_IncorrectKey() public {
        uint256 wrongPrivateKey = 2345;

        // generate permit signature
        address _owner = recipient;
        address _spender = address(0x789);
        uint256 _value = 1 ether;
        uint256 _deadline = 1000;

        uint256 _nonce = base.nonces(_owner);

        domainSeparator = keccak256(
            abi.encode(typehashEip712, permitNameHash, permitVersionHash, block.chainid, address(base))
        );
        bytes32 structHash = keccak256(abi.encode(permitTypeHash, _owner, _spender, _value, _nonce, _deadline));
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, typedDataHash); // sign with wrong key

        // call permit to approve _value to _spender
        vm.expectRevert("ERC20Permit: invalid signature");
        base.permit(_owner, _spender, _value, _deadline, v, r, s);
    }

    function test_revert_permit_UsedNonce() public {
        // generate permit signature
        address _owner = recipient;
        address _spender = address(0x789);
        uint256 _value = 1 ether;
        uint256 _deadline = 1000;

        uint256 _nonce = base.nonces(_owner);

        domainSeparator = keccak256(
            abi.encode(typehashEip712, permitNameHash, permitVersionHash, block.chainid, address(base))
        );
        bytes32 structHash = keccak256(abi.encode(permitTypeHash, _owner, _spender, _value, _nonce, _deadline));
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(recipientPrivateKey, typedDataHash);

        // call permit to approve _value to _spender
        base.permit(_owner, _spender, _value, _deadline, v, r, s);

        // sign again with same nonce
        (v, r, s) = vm.sign(recipientPrivateKey, typedDataHash);

        vm.expectRevert("ERC20Permit: invalid signature");
        base.permit(_owner, _spender, _value, _deadline, v, r, s);
    }

    function test_revert_permit_ExpiredDeadline() public {
        // generate permit signature
        address _owner = recipient;
        address _spender = address(0x789);
        uint256 _value = 1 ether;
        uint256 _deadline = 1000;

        uint256 _nonce = base.nonces(_owner);

        domainSeparator = keccak256(
            abi.encode(typehashEip712, permitNameHash, permitVersionHash, block.chainid, address(base))
        );
        bytes32 structHash = keccak256(abi.encode(permitTypeHash, _owner, _spender, _value, _nonce, _deadline));
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(recipientPrivateKey, typedDataHash);

        // call permit to approve _value to _spender
        vm.warp(_deadline + 1);
        vm.expectRevert("ERC20Permit: expired deadline");
        base.permit(_owner, _spender, _value, _deadline, v, r, s);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `mintWithSignature`
    //////////////////////////////////////////////////////////////*/

    function test_state_mintWithSignature_ZeroPrice() public {
        vm.warp(1000);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        address recoveredSigner = base.mintWithSignature(_mintrequest, _signature);

        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);
        assertEq(signer, recoveredSigner);
    }

    function test_state_mintWithSignature_NonZeroPrice_ERC20() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(erc20);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        erc20.approve(address(base), _mintrequest.quantity * _mintrequest.pricePerToken);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);
        uint256 erc20BalanceOfRecipient = erc20.balanceOf(recipient);
        uint256 erc20BalanceOfSeller = erc20.balanceOf(saleRecipient);

        uint256 totalPrice = (_mintrequest.quantity * _mintrequest.pricePerToken) / 1 ether;

        vm.prank(recipient);
        base.mintWithSignature(_mintrequest, _signature);

        // check token balances
        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);

        // check erc20 currency balances
        assertEq(erc20.balanceOf(recipient), erc20BalanceOfRecipient - totalPrice);
        assertEq(erc20.balanceOf(saleRecipient), erc20BalanceOfSeller + totalPrice);
    }

    function test_state_mintWithSignature_NonZeroPrice_NativeToken() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1 ether;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);
        uint256 etherBalanceOfRecipient = recipient.balance;
        uint256 etherBalanceOfSeller = saleRecipient.balance;

        uint256 totalPrice = (_mintrequest.quantity * _mintrequest.pricePerToken) / 1 ether;

        vm.prank(recipient);
        base.mintWithSignature{ value: totalPrice }(_mintrequest, _signature);

        assertEq(base.totalSupply(), currentTotalSupply + _mintrequest.quantity);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + _mintrequest.quantity);

        // check native-token balances
        assertEq(recipient.balance, etherBalanceOfRecipient - totalPrice);
        assertEq(saleRecipient.balance, etherBalanceOfSeller + totalPrice);
    }

    function test_revert_mintWithSignature_MustSendTotalPrice() public {
        vm.warp(1000);

        _mintrequest.pricePerToken = 1;
        _mintrequest.currency = address(NATIVE_TOKEN);
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.prank(recipient);
        vm.expectRevert("Must send total price.");
        base.mintWithSignature{ value: 0 }(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_MintingZeroTokens() public {
        vm.warp(1000);

        _mintrequest.quantity = 0;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("Minting zero tokens.");
        base.mintWithSignature(_mintrequest, _signature);
    }

    function test_revert_mintWithSignature_QuantityTooLow() public {
        vm.warp(1000);

        _mintrequest.quantity = 100;
        _mintrequest.pricePerToken = 1;
        _signature = signMintRequest(_mintrequest, privateKey);

        vm.expectRevert("quantity too low");
        base.mintWithSignature(_mintrequest, _signature);
    }
}
