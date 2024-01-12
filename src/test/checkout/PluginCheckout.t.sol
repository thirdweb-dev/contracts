// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { IDrop } from "contracts/extension/interface/IDrop.sol";
import { TWProxy } from "contracts/infra/TWProxy.sol";

import { PluginCheckout, IPluginCheckout } from "contracts/prebuilts/unaudited/checkout/PluginCheckout.sol";
import { IPRBProxyPlugin } from "@prb/proxy/src/interfaces/IPRBProxyPlugin.sol";
import { IPRBProxy } from "@prb/proxy/src/interfaces/IPRBProxy.sol";
import { IPRBProxyRegistry } from "@prb/proxy/src/interfaces/IPRBProxyRegistry.sol";
import { PRBProxy } from "@prb/proxy/src/PRBProxy.sol";
import { PRBProxyRegistry } from "@prb/proxy/src/PRBProxyRegistry.sol";

import "./IQuoter.sol";
import "./ISwapRouter.sol";

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

    // for fork testing of swap + execute
    uint256 internal mainnetFork;
    address quoterAddress = address(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); // UniswapV3 Quoter
    address swapRouterAddress = address(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniswapV3 SwapRouter
    address usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IQuoter quoter = IQuoter(quoterAddress);
    ISwapRouter router = ISwapRouter(swapRouterAddress);

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

    function setClaimConditionCurrency(DropERC721 drop, address _currency) public {
        DropERC721.ClaimCondition[] memory conditions = new DropERC721.ClaimCondition[](1);
        conditions[0].maxClaimableSupply = type(uint256).max;
        conditions[0].quantityLimitPerWallet = 100;
        conditions[0].pricePerToken = 10;
        conditions[0].currency = _currency;

        vm.prank(deployer);
        drop.setClaimConditions(conditions, false);
    }

    function _setupFork() internal {
        mainnetFork = vm.createFork("https://1.rpc.thirdweb.com");
        vm.selectFork(mainnetFork);
        vm.rollFork(18993216);

        // setup target NFT Drop contract
        address dropImpl = address(new DropERC721());
        targetDrop = DropERC721(
            address(
                new TWProxy(
                    dropImpl,
                    abi.encodeCall(
                        DropERC721.initialize,
                        (
                            deployer,
                            NAME,
                            SYMBOL,
                            CONTRACT_URI,
                            forwarders(),
                            saleRecipient,
                            royaltyRecipient,
                            royaltyBps,
                            platformFeeBps,
                            platformFeeRecipient
                        )
                    )
                )
            )
        );
        vm.prank(deployer);
        targetDrop.lazyMint(100, "ipfs://", "");
        setClaimConditionCurrency(targetDrop, dai);

        // deploy checkout contracts
        checkoutPlugin = new PluginCheckout();
        proxyRegistry = new PRBProxyRegistry();
        vm.prank(owner);
        proxy = PRBProxy(
            payable(address(proxyRegistry.deployAndInstallPlugin(IPRBProxyPlugin(address(checkoutPlugin)))))
        );

        // deal owner eth
        vm.deal(owner, 1000 ether);

        // get USDC to owner address
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: wethAddress,
            tokenOut: usdc,
            fee: 100,
            recipient: owner,
            deadline: type(uint256).max,
            amountIn: 1 ether,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });
        router.exactInputSingle{ value: 1 ether }(params);
        console.log(IERC20(usdc).balanceOf(owner));

        // transfer USDC from owner to proxy
        vm.prank(owner);
        IERC20(usdc).transfer(address(proxy), 1000000);

        // approve router on checkout proxy
        vm.prank(owner);
        PluginCheckout(address(proxy)).approveSwapRouter(swapRouterAddress, true);
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

    function test_revert_executeOp_notAuthorized() public {
        // create user op -- claim tokens on targetDrop
        bytes memory callData;
        IPluginCheckout.UserOp memory op = IPluginCheckout.UserOp({
            target: address(targetDrop),
            currency: address(mainCurrency),
            approvalRequired: true,
            valueToSend: 0,
            data: callData
        });

        // execute
        vm.prank(random);
        vm.expectRevert("Not authorized");
        PluginCheckout(address(proxy)).execute(op);
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

    function test_revert_withdraw_whenNotOwner() public {
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

    function test_swapAndExecute() public {
        _setupFork();

        IPluginCheckout.UserOp memory op;
        IPluginCheckout.UserOp memory swapOp;

        uint256 totalPriceForClaim;
        uint256 amountIn;

        // create user op -- to claim tokens on targetDrop
        {
            uint256 _quantityToClaim = 5;
            totalPriceForClaim = 5 * 10; // claim condition price is set as 10 above in setup
            DropERC721.AllowlistProof memory alp;
            bytes memory callData = abi.encodeWithSelector(
                IDrop.claim.selector,
                receiver,
                _quantityToClaim,
                dai, // we'll get DAI by swapping out our USDC
                10,
                alp,
                ""
            );
            op = IPluginCheckout.UserOp({
                target: address(targetDrop),
                currency: dai,
                approvalRequired: true,
                valueToSend: totalPriceForClaim,
                data: callData
            });
        }

        // get quote for swapping usdc for dai -- to pay for claiming
        {
            amountIn = quoter.quoteExactOutputSingle(
                usdc, // address tokenIn,
                dai, // address tokenOut,
                100, // uint24 fee,
                totalPriceForClaim, // uint256 amountOut,
                0 // uint160 sqrtPriceLimitX96
            );
            console.log(amountIn);
        }

        // create swapOp
        {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: usdc,
                tokenOut: dai,
                fee: 100,
                recipient: address(proxy),
                deadline: type(uint256).max,
                amountIn: amountIn,
                amountOutMinimum: totalPriceForClaim,
                sqrtPriceLimitX96: 0
            });
            bytes memory swapCalldata = abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, params);
            swapOp = IPluginCheckout.UserOp({
                target: swapRouterAddress,
                currency: usdc,
                approvalRequired: true,
                valueToSend: amountIn,
                data: swapCalldata
            });
        }

        // execute
        vm.prank(owner);
        PluginCheckout(address(proxy)).swapAndExecute(op, swapOp);
    }
}
