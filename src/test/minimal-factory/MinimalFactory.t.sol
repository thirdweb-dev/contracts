// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/infra/TWMinimalFactory.sol";
import "contracts/infra/TWProxy.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

import "../utils/BaseTest.sol";

contract DummyUpgradeable {
    uint256 public number;

    constructor() {}

    function initialize(uint256 _num) public {
        number = _num;
    }
}

contract TWNotMinimalFactory {
    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(address _implementation, bytes memory _data, bytes32 _salt) public {
        address deployedProxy = Clones.cloneDeterministic(_implementation, _salt);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedProxy, _data);
        }
    }
}

contract MinimalFactoryTest is BaseTest {
    address internal implementation;
    bytes32 internal salt;
    bytes internal data;
    address admin;

    TWNotMinimalFactory notMinimal;

    function setUp() public override {
        super.setUp();
        admin = getActor(5000);
        vm.startPrank(admin);
        implementation = getContract("TokenERC20");
        salt = keccak256("yooo");
        data = abi.encodeWithSelector(
            TokenERC20.initialize.selector,
            admin,
            "MinimalToken",
            "MT",
            "ipfs://notCentralized",
            new address[](0),
            admin,
            admin,
            50
        );

        notMinimal = new TWNotMinimalFactory();
    }

    // gas: Baseline + 140k
    function test_gas_twProxy() public {
        new TWProxy(implementation, data);
    }

    // gas: Baseline + 41.5k
    function test_gas_notMinimalFactory() public {
        notMinimal.deployProxyByImplementation(implementation, data, salt);
    }

    // gas: Baseline
    function test_gas_minimal() public {
        new TWMinimalFactory(implementation, data, salt);
    }

    function test_verify_deployedProxy() public {
        vm.stopPrank();
        vm.prank(address(0x123456));
        address minimalFactory = address(new TWMinimalFactory(implementation, data, salt));
        bytes32 salthash = keccak256(abi.encodePacked(address(0x123456), salt));
        address deployedProxy = Clones.predictDeterministicAddress(implementation, salthash, minimalFactory);

        bytes32 contractType = TokenERC20(deployedProxy).contractType();
        assertEq(contractType, bytes32("TokenERC20"));
    }
}
