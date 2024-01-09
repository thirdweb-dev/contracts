// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC20Drop } from "contracts/base/ERC20Drop.sol";

contract BaseERC20DropTest is BaseUtilTest {
    ERC20Drop internal base;
    using Strings for uint256;

    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    // permit
    bytes32 internal permitTypeHash;
    bytes32 internal permitNameHash;
    bytes32 internal permitVersionHash;

    uint256 public recipientPrivateKey = 5678;
    address public recipient;

    function setUp() public override {
        super.setUp();
        vm.prank(signer);
        base = new ERC20Drop(signer, NAME, SYMBOL, saleRecipient);

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
        conditions[0].quantityLimitPerWallet = 100;

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
        conditions[0].quantityLimitPerWallet = 100 ether;

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
        conditions[0].quantityLimitPerWallet = 100 ether;

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
        conditions[0].quantityLimitPerWallet = 100 ether;

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
}
