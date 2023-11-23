// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./AATestBase.sol";
import { ThirdwebAccountFactory, ThirdwebAccount, THIRDWEB_ACCOUNT_FACTORY_ADDRESS, THIRDWEB_ACCOUNT_IMPL_ADDRESS, THIRDWEB_ACCOUNT_FACTORY_BYTECODE, THIRDWEB_ACCOUNT_IMPL_BYTECODE } from "./AABenchmarkArtifacts.sol";

contract ProfileThirdwebAccount is AAGasProfileBase {
    ThirdwebAccountFactory factory;

    function setUp() external {
        initializeTest("thirdwebAccount");
        factory = ThirdwebAccountFactory(THIRDWEB_ACCOUNT_FACTORY_ADDRESS);
        vm.etch(address(factory), THIRDWEB_ACCOUNT_FACTORY_BYTECODE);
        vm.etch(THIRDWEB_ACCOUNT_IMPL_ADDRESS, THIRDWEB_ACCOUNT_IMPL_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(ThirdwebAccount.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        // if (address(account).code.length == 0) {
        factory.createAccount(_owner, "");
        // }
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        return IAccount(factory.getAddress(_owner, ""));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(address(factory), abi.encodeWithSelector(factory.createAccount.selector, _owner, ""));
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
            hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
