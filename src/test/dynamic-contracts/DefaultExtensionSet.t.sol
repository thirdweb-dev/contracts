// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IExtension.sol";
import "lib/dynamic-contracts/src/presets/utils/DefaultExtensionSet.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";
import "../mocks/MockERC1155.sol";
import { BaseTest } from "../utils/BaseTest.sol";

contract ContractA {
    uint256 private a_;

    function a() external {
        a_ += 1;
    }
}

contract ContractB {
    uint256 private b_;

    function b() external {
        b_ += 1;
    }
}

contract ContractC {
    uint256 private c_;

    function c() external {
        c_ += 1;
    }

    function getC() external view returns (uint256) {
        return c_;
    }
}

contract DefaultExtensionSetTest is BaseTest, IExtension {
    address private defaultExtensionSetDeployer;

    DefaultExtensionSet private defaultExtensionSet;

    mapping(uint256 => Extension) private extensions;

    function setUp() public override {
        super.setUp();

        defaultExtensionSetDeployer = address(0x123);

        vm.prank(defaultExtensionSetDeployer);
        defaultExtensionSet = new DefaultExtensionSet();

        // Add extension 1.

        extensions[0].metadata = ExtensionMetadata({
            name: "ContractA",
            metadataURI: "ipfs://ContractA",
            implementation: address(new ContractA())
        });

        extensions[0].functions.push(ExtensionFunction(ContractA.a.selector, "a()"));

        // Add extension 2.

        extensions[1].metadata = ExtensionMetadata({
            name: "ContractB",
            metadataURI: "ipfs://ContractB",
            implementation: address(new ContractB())
        });
        extensions[1].functions.push(ExtensionFunction(ContractB.b.selector, "b()"));

        // Add extension 3.

        extensions[2].metadata = ExtensionMetadata({
            name: "ContractC",
            metadataURI: "ipfs://ContractC",
            implementation: address(new ContractC())
        });
        extensions[2].functions.push(ExtensionFunction(ContractC.c.selector, "c()"));
    }

    function test_state_setExtension() external {
        uint256 len = 3;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(defaultExtensionSetDeployer);
            defaultExtensionSet.setExtension(extensions[i]);
        }
        Extension[] memory getAllExtensions = defaultExtensionSet.getAllExtensions();

        for (uint256 i = 0; i < len; i += 1) {
            // getAllExtensions
            assertEq(getAllExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
            assertEq(getAllExtensions[i].metadata.name, extensions[i].metadata.name);
            assertEq(getAllExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
            uint256 fnsLen = extensions[i].functions.length;
            assertEq(fnsLen, getAllExtensions[i].functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(
                    extensions[i].functions[j].functionSelector,
                    getAllExtensions[i].functions[j].functionSelector
                );
                assertEq(
                    extensions[i].functions[j].functionSignature,
                    getAllExtensions[i].functions[j].functionSignature
                );
            }

            // getExtension
            Extension memory extension = defaultExtensionSet.getExtension(extensions[i].metadata.name);
            assertEq(extension.metadata.implementation, extensions[i].metadata.implementation);
            assertEq(extension.metadata.name, extensions[i].metadata.name);
            assertEq(extension.metadata.metadataURI, extensions[i].metadata.metadataURI);
            assertEq(fnsLen, extension.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extensions[i].functions[j].functionSelector, extension.functions[j].functionSelector);
                assertEq(extensions[i].functions[j].functionSignature, extension.functions[j].functionSignature);
            }
        }
        for (uint256 i = 0; i < len; i += 1) {
            string memory name = extensions[i].metadata.name;
            ExtensionFunction[] memory functions = defaultExtensionSet.getAllFunctionsOfExtension(name);
            uint256 fnsLen = extensions[i].functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extensions[i].functions[j].functionSelector, functions[j].functionSelector);
                assertEq(extensions[i].functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        for (uint256 i = 0; i < len; i += 1) {
            ExtensionMetadata memory metadata = extensions[i].metadata;
            ExtensionFunction[] memory functions = extensions[i].functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                ExtensionMetadata memory extension = defaultExtensionSet.getExtensionForFunction(
                    functions[j].functionSelector
                );
                assertEq(extension.implementation, metadata.implementation);
                assertEq(extension.name, metadata.name);
                assertEq(extension.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, defaultExtensionSet.getExtensionImplementation(metadata.name));
        }
    }

    function test_revert_setExtension_nonDeployerCaller() external {
        vm.expectRevert("DefaultExtensionSet: unauthorized caller.");
        vm.prank(address(0x999));
        defaultExtensionSet.setExtension(extensions[0]);
    }

    function test_revert_addExtensionsWithSameFunctionSelectors() external {
        // Add extension 1.

        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        // Add extension 2.

        Extension memory extension2;

        extension2.metadata = ExtensionMetadata({
            name: "MockERC721",
            metadataURI: "ipfs://MockERC721",
            implementation: address(new MockERC721())
        });

        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(MockERC721.mint.selector, "mint(address,uint256)");

        vm.startPrank(defaultExtensionSetDeployer);

        defaultExtensionSet.setExtension(extension1);

        vm.expectRevert("ExtensionState: extension already exists for function.");
        defaultExtensionSet.setExtension(extension2);

        vm.stopPrank();
    }

    function test_revert_fnSelectorSignatureMismatch() external {
        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "hello()");

        vm.prank(defaultExtensionSetDeployer);
        vm.expectRevert("ExtensionState: fn selector and signature mismatch.");
        defaultExtensionSet.setExtension(extension1);
    }

    function test_revert_sameExtensionName() external {
        // Add extension 1.

        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        // Add extension 2.

        Extension memory extension2;

        extension2.metadata = ExtensionMetadata({
            name: "MockERC20", // same extension name
            metadataURI: "ipfs://MockERC721",
            implementation: address(new MockERC721())
        });

        extension2.functions = new ExtensionFunction[](1);
        extension2.functions[0] = ExtensionFunction(MockERC721.mint.selector, "mint(address,uint256)");

        vm.startPrank(defaultExtensionSetDeployer);

        defaultExtensionSet.setExtension(extension1);

        vm.expectRevert("ExtensionState: extension already exists.");
        defaultExtensionSet.setExtension(extension2);

        vm.stopPrank();
    }

    function test_revert_emptyExtensionImplementation() external {
        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(0)
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(defaultExtensionSetDeployer);
        vm.expectRevert("ExtensionState: adding extension without implementation.");
        defaultExtensionSet.setExtension(extension1);
    }
}
