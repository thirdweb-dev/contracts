// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Test utils
import { BaseTest } from "../../utils/BaseTest.sol";

// Account Abstraction setup for smart wallets.
import { IEntryPoint } from "contracts/prebuilts/account/utils/Entrypoint.sol";
import { Strings } from "contracts/lib/Strings.sol";
import { AccountFactory } from "contracts/prebuilts/account/non-upgradeable/AccountFactory.sol";
import "forge-std/Test.sol";

contract AABenchmarkPrepare is BaseTest {
    AccountFactory private accountFactory;

    function setUp() public override {
        super.setUp();
        accountFactory = new AccountFactory(
            deployer,
            IEntryPoint(payable(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)))
        );
    }

    function test_prepareBenchmarkFile() public {
        address accountFactoryAddress = address(accountFactory);
        bytes memory accountFactoryBytecode = accountFactoryAddress.code;

        address accountImplAddress = accountFactory.accountImplementation();
        bytes memory accountImplBytecode = accountImplAddress.code;

        string memory accountFactoryAddressString = string.concat(
            "address constant THIRDWEB_ACCOUNT_FACTORY_ADDRESS = ",
            Strings.toHexStringChecksummed(accountFactoryAddress),
            ";"
        );
        string memory accountFactoryBytecodeString = string.concat(
            'bytes constant THIRDWEB_ACCOUNT_FACTORY_BYTECODE = hex"',
            Strings.toHexStringNoPrefix(accountFactoryBytecode),
            '"',
            ";"
        );

        string memory accountImplAddressString = string.concat(
            "address constant THIRDWEB_ACCOUNT_IMPL_ADDRESS = ",
            Strings.toHexStringChecksummed(accountImplAddress),
            ";"
        );
        string memory accountImplBytecodeString = string.concat(
            'bytes constant THIRDWEB_ACCOUNT_IMPL_BYTECODE = hex"',
            Strings.toHexStringNoPrefix(accountImplBytecode),
            '"',
            ";"
        );

        string memory path = "src/test/smart-wallet/utils/AABenchmarkArtifacts.sol";

        vm.removeFile(path);

        vm.writeLine(path, "");
        vm.writeLine(path, "pragma solidity ^0.8.0;");
        vm.writeLine(path, "interface ThirdwebAccountFactory {");
        vm.writeLine(
            path,
            "    function createAccount(address _admin, bytes calldata _data) external returns (address);"
        );
        vm.writeLine(
            path,
            "    function getAddress(address _adminSigner, bytes calldata _data) external view returns (address);"
        );
        vm.writeLine(path, "}");

        vm.writeLine(path, "interface ThirdwebAccount {");
        vm.writeLine(path, "    function execute(address _target, uint256 _value, bytes calldata _calldata) external;");
        vm.writeLine(path, "}");
        vm.writeLine(path, accountFactoryAddressString);
        vm.writeLine(path, accountImplAddressString);
        vm.writeLine(path, accountFactoryBytecodeString);
        vm.writeLine(path, accountImplBytecodeString);

        vm.writeLine(path, "");
    }
}
