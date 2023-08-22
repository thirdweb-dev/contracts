// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Test imports
import "./mocks/MockThirdwebContract.sol";
import "./utils/BaseTest.sol";
import "contracts/infra/TWFee.sol";

// Helpers
import "@openzeppelin/contracts/utils/Create2.sol";
import "contracts/infra/TWRegistry.sol";
import "contracts/infra/TWFactory.sol";
import "contracts/infra/TWProxy.sol";

contract TWFeeTest is BaseTest {
    // Target contract
    TWFee internal twFee;

    // Helper contracts
    TWRegistry internal twRegistry;
    TWFactory internal twFactory;
    MockThirdwebContract internal mockModule;

    // Actors
    address internal mockModuleDeployer;
    address internal moduleAdmin = address(0x1);
    address internal feeAdmin = address(0x2);
    address internal notFeeAdmin = address(0x3);
    address internal payer = address(0x4);

    // Test params
    address internal trustedForwarder = address(0x4);
    address internal thirdwebTreasury = address(0x5);

    //  =====   Set up  =====

    function setUp() public override {}
}
