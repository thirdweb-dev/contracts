// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { DropERC20 } from "contracts/prebuilts/drop/DropERC20.sol";

// Test imports
import "contracts/lib/TWStrings.sol";
import "../../../utils/BaseTest.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "lib/forge-std/src/StdCheats.sol";

contract HarnessDropERC20Misc is DropERC20 {
    bytes32 private transferRole;

    function initializeHarness(
        address _defaultAdmin,
        string memory _contractURI,
        address _saleRecipient,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");

        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
        _setupPrimarySaleRecipient(_saleRecipient);

        transferRole = _transferRole;
    }

    function msgData() public view returns (bytes memory) {
        return _msgData();
    }

    function transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed) public returns (uint256) {
        return _transferTokensOnClaim(_to, _quantityBeingClaimed);
    }

    function beforeTokenTransfer(address from, address to, uint256 amount) public {
        _beforeTokenTransfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

    function hasTransferRole(address _account) public view returns (bool) {
        return hasRole(transferRole, _account);
    }
}

contract DropERC20Test_misc is BaseTest {
    using StringsUpgradeable for uint256;

    HarnessDropERC20Misc public dropHarness;
    DropERC20 public drop;

    function setUp() public override {
        super.setUp();

        dropHarness = new HarnessDropERC20Misc();
        dropHarness.initializeHarness(deployer, CONTRACT_URI, saleRecipient, platformFeeBps, platformFeeRecipient);

        drop = DropERC20(getContract("DropERC20"));
    }

    modifier callerHasDefaultAdminRole() {
        vm.startPrank(deployer);
        _;
    }

    modifier callerDoesNotHaveDefaultAdminRole() {
        _;
    }

    function test_contractType_returnValue() public {
        assertEq(drop.contractType(), "DropERC20");
    }

    function test_contractVersion_returnValue() public {
        assertEq(drop.contractVersion(), uint8(4));
    }

    function test_msgData_returnValue() public {
        bytes memory msgData = dropHarness.msgData();
        bytes4 expectedData = dropHarness.msgData.selector;
        assertEq(bytes4(msgData), expectedData);
    }

    function test_state_transferTokensOnClaim() public {
        uint256 initialBalance = drop.balanceOf(deployer);
        uint256 quantityBeingClaimed = 1;
        dropHarness.transferTokensOnClaim(deployer, quantityBeingClaimed);
        assertEq(dropHarness.balanceOf(deployer), initialBalance + quantityBeingClaimed);
    }

    function test_returnValue_transferTokensOnClaim() public {
        uint256 quantityBeingClaimed = 1;
        uint256 returnValue = dropHarness.transferTokensOnClaim(deployer, quantityBeingClaimed);
        assertEq(returnValue, 0);
    }

    function test_beforeTokenTransfer_revert_addressZeroNoTransferRole() public {
        vm.prank(deployer);
        dropHarness.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        vm.expectRevert("transfers restricted.");
        dropHarness.beforeTokenTransfer(address(0x01), address(0x02), 1);
    }

    function test_beforeTokenTransfer_doesNotRevert_addressZeroNoTransferRole_burnMint() public {
        vm.prank(deployer);
        dropHarness.revokeRole(keccak256("TRANSFER_ROLE"), address(0));
        dropHarness.beforeTokenTransfer(address(0), address(0x02), 1);
        dropHarness.beforeTokenTransfer(address(0x01), address(0), 1);
    }

    function test_state_mint() public {
        uint256 initialBalance = drop.balanceOf(deployer);
        uint256 amount = 1;
        dropHarness.mint(deployer, amount);
        assertEq(dropHarness.balanceOf(deployer), initialBalance + amount);
    }

    function test_state_burn() public {
        dropHarness.mint(deployer, 1);
        uint256 initialBalance = dropHarness.balanceOf(deployer);
        uint256 amount = 1;
        dropHarness.burn(deployer, amount);
        assertEq(dropHarness.balanceOf(deployer), initialBalance - amount);
    }

    function test_transfer_drop() public {
        //deal erc20 drop to address(0x1)
        deal(address(drop), address(0x1), 1);
        vm.prank(address(0x1));
        drop.transfer(address(0x2), 1);
        assertEq(drop.balanceOf(address(0x2)), 1);
    }
}
