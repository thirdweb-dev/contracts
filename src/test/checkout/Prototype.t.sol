// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { Checkout, ICheckout } from "contracts/prebuilts/unaudited/checkout/Checkout.sol";
import { Vault, IVault } from "contracts/prebuilts/unaudited/checkout/Vault.sol";
import { Executor, IExecutor } from "contracts/prebuilts/unaudited/checkout/Checkout.sol";
import { IDrop } from "contracts/extension/interface/IDrop.sol";

contract CheckoutPrototypeTest is BaseTest {
    address internal vaultImplementation;
    address internal executorImplementation;

    Checkout internal checkout;

    Vault internal vaultOne;
    Vault internal vaultTwo;
    Executor internal executorOne;
    Executor internal executorTwo;

    address internal vaultAdminOne;
    address internal vaultAdminTwo;
    address internal executorAdminOne;
    address internal executorAdminTwo;

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
        vaultAdminOne = getActor(1);
        vaultAdminTwo = getActor(2);
        executorAdminOne = getActor(3);
        executorAdminTwo = getActor(4);
        receiver = getActor(5);

        // setup currencies
        mainCurrency = new MockERC20();
        altCurrencyOne = new MockERC20();
        altCurrencyTwo = new MockERC20();

        // mint and approve  currencies
        mainCurrency.mint(address(vaultAdminOne), 100 ether);
        altCurrencyOne.mint(address(vaultAdminOne), 100 ether);
        altCurrencyTwo.mint(address(vaultAdminOne), 100 ether);
        mainCurrency.mint(address(vaultAdminTwo), 100 ether);
        altCurrencyOne.mint(address(vaultAdminTwo), 100 ether);
        altCurrencyTwo.mint(address(vaultAdminTwo), 100 ether);

        // setup target NFT Drop contract
        targetDrop = DropERC721(getContract("DropERC721"));
        vm.prank(deployer);
        targetDrop.lazyMint(100, "ipfs://", "");
        setClaimConditionCurrency(targetDrop, address(mainCurrency));

        // deploy vault and executor implementations
        vaultImplementation = address(new Vault());
        executorImplementation = address(new Executor());

        // deploy checkout
        checkout = new Checkout(deployer, vaultImplementation, executorImplementation);
    }

    function test_checkout_createVault() public {
        vaultOne = Vault(checkout.createVault(vaultAdminOne, "vaultAdminOne"));

        assertEq(vaultOne.checkout(), address(checkout));
        assertTrue(vaultOne.hasRole(bytes32(0x00), vaultAdminOne));
        assertTrue(checkout.isVaultRegistered(address(vaultOne)));

        // should revert when deploying with same salt again
        vm.expectRevert("ERC1167: create2 failed");
        checkout.createVault(vaultAdminOne, "vaultAdminOne");
    }

    function test_checkout_createExecutor() public {
        executorOne = Executor(payable(checkout.createExecutor(executorAdminOne, "executorAdminOne")));

        assertEq(executorOne.checkout(), address(checkout));
        assertTrue(executorOne.hasRole(bytes32(0x00), executorAdminOne));
        assertTrue(checkout.isExecutorRegistered(address(executorOne)));

        // should revert when deploying with same salt again
        vm.expectRevert("ERC1167: create2 failed");
        checkout.createExecutor(executorAdminOne, "executorAdminOne");
    }

    function test_checkout_authorizeVaultToExecutor() public {
        vaultOne = Vault(checkout.createVault(vaultAdminOne, "vaultAdminOne"));
        executorOne = Executor(payable(checkout.createExecutor(executorAdminOne, "executorAdminOne")));

        vm.prank(vaultAdminOne);
        checkout.authorizeVaultToExecutor(address(vaultOne), address(executorOne));
        assertEq(vaultOne.executor(), address(executorOne));

        // revert for unauthorized caller
        vm.prank(address(0x123));
        vm.expectRevert("Not authorized");
        checkout.authorizeVaultToExecutor(address(vaultOne), address(executorOne));

        // revert for unknown executor
        vm.prank(vaultAdminOne);
        vm.expectRevert("Executor not found");
        checkout.authorizeVaultToExecutor(address(vaultOne), address(0x123));
    }

    function test_executor_executeOp() public {
        // setup contracts
        vaultOne = Vault(checkout.createVault(vaultAdminOne, "vaultAdminOne"));
        executorOne = Executor(payable(checkout.createExecutor(executorAdminOne, "executorAdminOne")));

        vm.prank(vaultAdminOne);
        checkout.authorizeVaultToExecutor(address(vaultOne), address(executorOne));

        // deposit currencies in vault
        vm.startPrank(address(vaultAdminOne));
        mainCurrency.approve(address(vaultOne), type(uint256).max);
        vaultOne.deposit(address(mainCurrency), 10 ether);
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
        IExecutor.UserOp memory op = IExecutor.UserOp({
            target: address(targetDrop),
            currency: address(mainCurrency),
            vault: address(vaultOne),
            approvalRequired: true,
            valueToSend: _totalPrice,
            data: callData
        });

        // check state before
        assertEq(targetDrop.balanceOf(receiver), 0);
        assertEq(targetDrop.nextTokenIdToClaim(), 0);
        assertEq(mainCurrency.balanceOf(address(vaultOne)), 10 ether);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), 0);
        assertEq(mainCurrency.allowance(address(vaultOne), address(executorOne)), 0);

        // execute
        vm.prank(executorAdminOne);
        executorOne.execute(op);

        // check state after
        assertEq(targetDrop.balanceOf(receiver), _quantityToClaim);
        assertEq(targetDrop.nextTokenIdToClaim(), _quantityToClaim);
        assertEq(mainCurrency.balanceOf(address(vaultOne)), 10 ether - _totalPrice);
        assertEq(mainCurrency.balanceOf(address(saleRecipient)), _totalPrice - (_totalPrice * platformFeeBps) / 10_000);
        assertEq(mainCurrency.allowance(address(vaultOne), address(executorOne)), 0);
    }
}
