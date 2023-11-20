// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../utils/BaseTest.sol";

import { TWProxy } from "contracts/infra/TWProxy.sol";

contract MyTokenERC20 is TokenERC20 {}

contract TokenERC20Test_MintTo is BaseTest {
    address public implementation;
    address public proxy;
    address public caller;
    address public recipient;
    uint256 public amount;

    MyTokenERC20 internal tokenContract;

    event TokensMinted(address indexed mintedTo, uint256 quantityMinted);

    function setUp() public override {
        super.setUp();

        // Deploy implementation.
        implementation = address(new MyTokenERC20());
        caller = getActor(1);
        recipient = getActor(2);

        // Deploy proxy pointing to implementaion.
        vm.prank(deployer);
        proxy = address(
            new TWProxy(
                implementation,
                abi.encodeCall(
                    TokenERC20.initialize,
                    (
                        deployer,
                        NAME,
                        SYMBOL,
                        CONTRACT_URI,
                        forwarders(),
                        saleRecipient,
                        platformFeeRecipient,
                        platformFeeBps
                    )
                )
            )
        );

        tokenContract = MyTokenERC20(proxy);
        amount = 100;
    }

    function test_mintTo_notMinterRole() public {
        vm.prank(caller);
        vm.expectRevert("not minter.");
        tokenContract.mintTo(recipient, amount);
    }

    modifier whenMinterRole() {
        vm.prank(deployer);
        tokenContract.grantRole(keccak256("MINTER_ROLE"), caller);
        _;
    }

    function test_mintTo() public whenMinterRole {
        // mint
        vm.prank(caller);
        tokenContract.mintTo(recipient, amount);

        // check state after
        assertEq(tokenContract.balanceOf(recipient), amount);
    }

    function test_mintTo_TokensMintedEvent() public whenMinterRole {
        vm.prank(caller);
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(recipient, amount);
        tokenContract.mintTo(recipient, amount);
    }
}
