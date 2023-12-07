// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@std/Test.sol";
import "@ds-test/test.sol";

import "./BaseUtilTest.sol";
import { ERC20Base } from "contracts/base/ERC20Base.sol";

contract BaseERC20BaseTest is BaseUtilTest {
    ERC20Base internal base;
    using Strings for uint256;

    bytes32 internal permitTypeHash;
    bytes32 internal permitNameHash;
    bytes32 internal permitVersionHash;
    bytes32 internal typehashEip712;
    bytes32 internal domainSeparator;

    uint256 public recipientPrivateKey = 5678;
    address public recipient;

    function setUp() public override {
        super.setUp();
        vm.prank(deployer);
        base = new ERC20Base(deployer, NAME, SYMBOL);

        recipient = vm.addr(recipientPrivateKey);

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
                        Unit tests: `mint`
    //////////////////////////////////////////////////////////////*/

    function test_state_mint() public {
        uint256 amount = 5 ether;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.mintTo(recipient, amount);

        assertEq(base.totalSupply(), currentTotalSupply + amount);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + amount);
    }

    function test_revert_mint_NotAuthorized() public {
        uint256 amount = 5 ether;

        vm.expectRevert("Not authorized to mint.");
        vm.prank(address(0x1));
        base.mintTo(recipient, amount);
    }

    function test_revert_mint_MintingZeroTokens() public {
        uint256 amount = 0;

        vm.expectRevert("Minting zero tokens.");
        vm.prank(deployer);
        base.mintTo(recipient, amount);
    }

    function test_revert_mint_MintToZeroAddress() public {
        uint256 amount = 1;

        vm.expectRevert("ERC20: mint to the zero address");
        vm.prank(deployer);
        base.mintTo(address(0), amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `burn`
    //////////////////////////////////////////////////////////////*/

    function test_state_burn() public {
        uint256 amount = 5 ether;

        uint256 currentTotalSupply = base.totalSupply();
        uint256 currentBalanceOfRecipient = base.balanceOf(recipient);

        vm.prank(deployer);
        base.mintTo(recipient, amount);

        assertEq(base.totalSupply(), currentTotalSupply + amount);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient + amount);

        // burn minted tokens
        currentTotalSupply = base.totalSupply();
        currentBalanceOfRecipient = base.balanceOf(recipient);
        vm.prank(recipient);
        base.burn(amount);

        assertEq(base.totalSupply(), currentTotalSupply - amount);
        assertEq(base.balanceOf(recipient), currentBalanceOfRecipient - amount);
    }

    function test_revert_burn_NotEnoughBalance() public {
        uint256 amount = 5 ether;

        vm.prank(deployer);
        base.mintTo(recipient, amount);

        vm.expectRevert("not enough balance");
        vm.prank(recipient);
        base.burn(amount + 1);
    }

    /*///////////////////////////////////////////////////////////////
                        Unit tests: `permit`
    //////////////////////////////////////////////////////////////*/

    function test_state_permit() public {
        uint256 amount = 5 ether;

        // mint amount to recipient
        vm.prank(deployer);
        base.mintTo(recipient, amount);

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
        uint256 amount = 5 ether;
        uint256 wrongPrivateKey = 2345;

        // mint amount to recipient
        vm.prank(deployer);
        base.mintTo(recipient, amount);

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
        uint256 amount = 5 ether;

        // mint amount to recipient
        vm.prank(deployer);
        base.mintTo(recipient, amount);

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
        uint256 amount = 5 ether;
        // uint256 wrongPrivateKey = 2345;

        // mint amount to recipient
        vm.prank(deployer);
        base.mintTo(recipient, amount);

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
