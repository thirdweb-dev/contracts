// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { IDrop } from "contracts/extension/interface/IDrop.sol";

import { PluginCheckout, IPluginCheckout } from "contracts/prebuilts/unaudited/checkout/PluginCheckout.sol";
import { IPRBProxyPlugin } from "@prb/proxy/src/interfaces/IPRBProxyPlugin.sol";
import { IPRBProxy } from "@prb/proxy/src/interfaces/IPRBProxy.sol";
import { IPRBProxyRegistry } from "@prb/proxy/src/interfaces/IPRBProxyRegistry.sol";
import { PRBProxy } from "@prb/proxy/src/PRBProxy.sol";
import { PRBProxyRegistry } from "@prb/proxy/src/PRBProxyRegistry.sol";

contract PluginCheckoutTest is BaseTest {
    PluginCheckout internal checkoutPlugin;
    PRBProxy internal proxy;
    PRBProxyRegistry internal proxyRegistry;

    address internal owner;
    address internal alice;
    address internal bob;
    address internal random;

    address internal receiver;

    DropERC721 internal targetDrop;

    MockERC20 internal mainCurrency;
    MockERC20 internal altCurrencyOne;
    MockERC20 internal altCurrencyTwo;

    function setClaimConditionCurrency(DropERC721 drop, address _currency) public {
        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = type(uint256).max;
        conditions[0].quantityLimitPerWallet = 100;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = _currency;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);
    }

    function setUp() public override {
        super.setUp();

        // setup actors
        owner = getActor(1);
        alice = getActor(2);
        bob = getActor(3);
        random = getActor(4);
        receiver = getActor(5);

        // setup currencies
        mainCurrency = new MockERC20();
        altCurrencyOne = new MockERC20();
        altCurrencyTwo = new MockERC20();

        // mint and approve  currencies
        mainCurrency.mint(address(owner), 100 ether);
        altCurrencyOne.mint(address(owner), 100 ether);
        altCurrencyTwo.mint(address(owner), 100 ether);

        // setup target NFT Drop contract
        targetDrop = DropERC721(getContract("DropERC721"));
        vm.prank(deployer);
        targetDrop.lazyMint(100, "ipfs://", "");
        setClaimConditionCurrency(targetDrop, address(mainCurrency));

        // deploy contracts
        checkoutPlugin = new PluginCheckout();
        proxyRegistry = new PRBProxyRegistry();

        vm.prank(owner);
        proxy = PRBProxy(
            payable(address(proxyRegistry.deployAndInstallPlugin(IPRBProxyPlugin(address(checkoutPlugin)))))
        );
    }

    function test_executeOp() public {
        // deposit currencies in vault
        vm.startPrank(owner);
        mainCurrency.transfer(address(proxy), 10 ether);
        vm.stopPrank();

        // create user op -- claim tokens on targetDrop
        uint256 _quantityToClaim = 5;
        uint256 _totalPrice = 5 * 10; // claim condition price is set as 10 above in setup
        DropERC721.AllowlistProof memory alp;
        bytes memory callData = abi.encodeWithSelector(
            IDrop.claim.selector,
            receiver,
            _quantityToClaim,
            address(mainCurrency),
            10,
            alp,
            ""
        );
        IPluginCheckout.UserOp memory op = IPluginCheckout.UserOp({
            target: address(targetDrop),
            currency: address(mainCurrency),
            approvalRequired: true,
            valueToSend: _totalPrice,
            data: callData
        });

        // check state before
        assertEq(targetDrop.balanceOf(receiver), 0);
        assertEq(targetDrop.nextTokenIdToClaim(), 0);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), 0);

        // execute
        vm.prank(owner);
        PluginCheckout(address(proxy)).execute(op);

        // check state after
        assertEq(targetDrop.balanceOf(receiver), _quantityToClaim);
        assertEq(targetDrop.nextTokenIdToClaim(), _quantityToClaim);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether - _totalPrice);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), _totalPrice - (_totalPrice * platformFeeBps) / 10_000);
    }

    function test_executeOp_permittedEOA() public {
        // deposit currencies in vault
        vm.startPrank(owner);
        mainCurrency.transfer(address(proxy), 10 ether);
        proxyRegistry.setPermission(alice, address(targetDrop), true); // permit other EOA
        vm.stopPrank();

        // create user op -- claim tokens on targetDrop
        uint256 _quantityToClaim = 5;
        uint256 _totalPrice = 5 * 10; // claim condition price is set as 10 above in setup
        DropERC721.AllowlistProof memory alp;
        bytes memory callData = abi.encodeWithSelector(
            IDrop.claim.selector,
            receiver,
            _quantityToClaim,
            address(mainCurrency),
            10,
            alp,
            ""
        );
        IPluginCheckout.UserOp memory op = IPluginCheckout.UserOp({
            target: address(targetDrop),
            currency: address(mainCurrency),
            approvalRequired: true,
            valueToSend: _totalPrice,
            data: callData
        });

        // check state before
        assertEq(targetDrop.balanceOf(receiver), 0);
        assertEq(targetDrop.nextTokenIdToClaim(), 0);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), 0);

        // execute
        vm.prank(alice); // non-owner EOA
        PluginCheckout(address(proxy)).execute(op);

        // check state after
        assertEq(targetDrop.balanceOf(receiver), _quantityToClaim);
        assertEq(targetDrop.nextTokenIdToClaim(), _quantityToClaim);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether - _totalPrice);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), _totalPrice - (_totalPrice * platformFeeBps) / 10_000);
    }

    function test_withdraw_owner() public {
        // add currency
        vm.prank(owner);
        mainCurrency.transfer(address(proxy), 10 ether);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether);
        assertEq(mainCurrency.balanceOf(owner), 90 ether);

        // withdraw
        vm.prank(owner);
        PluginCheckout(address(proxy)).withdraw(address(mainCurrency), 5 ether);
        assertEq(mainCurrency.balanceOf(address(proxy)), 5 ether);
        assertEq(mainCurrency.balanceOf(owner), 95 ether);
    }

    function test_withdraw_whenNotOwner() public {
        // add currency
        vm.prank(owner);
        mainCurrency.transfer(address(proxy), 10 ether);
        assertEq(mainCurrency.balanceOf(address(proxy)), 10 ether);
        assertEq(mainCurrency.balanceOf(owner), 90 ether);

        // withdraw
        vm.prank(random);
        vm.expectRevert("Not authorized");
        PluginCheckout(address(proxy)).withdraw(address(mainCurrency), 5 ether);
    }
}
