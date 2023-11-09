// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../utils/BaseTest.sol";

import { Checkout, ICheckout } from "contracts/prebuilts/unaudited/checkout/Checkout.sol";
import { Vault, IVault } from "contracts/prebuilts/unaudited/checkout/Vault.sol";
import { Executor, IExecutor } from "contracts/prebuilts/unaudited/checkout/Checkout.sol";

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

        // setup currencies
        mainCurrency = new MockERC20();
        altCurrencyOne = new MockERC20();
        altCurrencyTwo = new MockERC20();

        // setup target NFT Drop contract
        targetDrop = DropERC721(getContract("DropERC721"));
        vm.prank(deployer);
        targetDrop.lazyMint(100, "ipfs://", "");
        setClaimConditionCurrency(targetDrop, address(mainCurrency));

        // deploy vault and executor implementations
        vaultImplementation = address(new Vault(address(mainCurrency)));
        executorImplementation = address(new Executor());

        // deploy checkout
        checkout = new Checkout(deployer, vaultImplementation, executorImplementation);
    }

    function test_checkout_createVault() public {
        vaultOne = Vault(checkout.createVault(vaultAdminOne, "vaultAdminOne"));

        assertEq(vaultOne.checkout(), address(checkout));
        assertTrue(vaultOne.hasRole(bytes32(0x00), vaultAdminOne));

        // should revert when deploying with same salt again
        vm.expectRevert("ERC1167: create2 failed");
        checkout.createVault(vaultAdminOne, "vaultAdminOne");
    }

    function test_checkout_createExecutor() public {
        executorOne = Executor(payable(checkout.createExecutor(executorAdminOne, "executorAdminOne")));

        assertEq(executorOne.checkout(), address(checkout));
        assertTrue(executorOne.hasRole(bytes32(0x00), executorAdminOne));

        // should revert when deploying with same salt again
        vm.expectRevert("ERC1167: create2 failed");
        checkout.createExecutor(executorAdminOne, "executorAdminOne");
    }
}
