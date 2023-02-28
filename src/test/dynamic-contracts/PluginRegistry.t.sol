// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IExtension.sol";
import "contracts/dynamic-contracts/ExtensionRegistry.sol";
import { BaseTest } from "../utils/BaseTest.sol";

import "../mocks/MockERC20.sol";
import "../mocks/MockERC721.sol";

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

contract ExtensionRegistryTest is BaseTest, IExtension {
    address private registryDeployer;

    ExtensionRegistry private extensionRegistry;

    mapping(uint256 => Extension) private extensions;

    function setUp() public override {
        super.setUp();

        registryDeployer = address(0x123);

        vm.prank(registryDeployer);
        extensionRegistry = new ExtensionRegistry(registryDeployer);

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

    /*///////////////////////////////////////////////////////////////
                            Adding extensions
    //////////////////////////////////////////////////////////////*/

    function test_state_addExtension() external {
        uint256 len = 3;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(registryDeployer);
            extensionRegistry.addExtension(extensions[i]);
        }
        Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();

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
            Extension memory extension = extensionRegistry.getExtension(extensions[i].metadata.name);
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
            ExtensionFunction[] memory functions = extensionRegistry.getAllFunctionsOfExtension(name);
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
                ExtensionMetadata memory extension = extensionRegistry.getExtensionForFunction(
                    functions[j].functionSelector
                );
                assertEq(extension.implementation, metadata.implementation);
                assertEq(extension.name, metadata.name);
                assertEq(extension.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, extensionRegistry.getExtensionImplementation(metadata.name));
        }
    }

    function test_revert_addExtension_unauthorizedCaller() external {
        vm.expectRevert();
        vm.prank(address(0x999));
        extensionRegistry.addExtension(extensions[0]);
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

        vm.startPrank(registryDeployer);

        extensionRegistry.addExtension(extension1);

        vm.expectRevert("ExtensionState: extension already exists for function.");
        extensionRegistry.addExtension(extension2);

        vm.stopPrank();
    }

    function test_revert_addExtension_fnSelectorSignatureMismatch() external {
        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "hello()");

        vm.prank(registryDeployer);
        vm.expectRevert("ExtensionState: fn selector and signature mismatch.");
        extensionRegistry.addExtension(extension1);
    }

    function test_revert_addExtension_sameExtensionName() external {
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

        vm.startPrank(registryDeployer);

        extensionRegistry.addExtension(extension1);

        vm.expectRevert("ExtensionState: extension already exists.");
        extensionRegistry.addExtension(extension2);

        vm.stopPrank();
    }

    function test_revert_addExtension_emptyExtensionImplementation() external {
        Extension memory extension1;

        extension1.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(0)
        });

        extension1.functions = new ExtensionFunction[](1);
        extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        vm.expectRevert("ExtensionState: adding extension without implementation.");
        extensionRegistry.addExtension(extension1);
    }

    /*///////////////////////////////////////////////////////////////
                            Updating extensions
    //////////////////////////////////////////////////////////////*/

    function _setUp_updateExtension() internal {
        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        extensionRegistry.addExtension(extension);
    }

    function test_state_updateExtension_someNewFunctions() external {
        _setUp_updateExtension();

        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");
        extension.functions[1] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extension);

        {
            Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
            assertEq(getAllExtensions.length, 1);

            // getAllExtensions
            assertEq(getAllExtensions[0].metadata.implementation, extension.metadata.implementation);
            assertEq(getAllExtensions[0].metadata.name, extension.metadata.name);
            assertEq(getAllExtensions[0].metadata.metadataURI, extension.metadata.metadataURI);
            uint256 fnsLen = extension.functions.length;

            assertEq(fnsLen, 2);
            assertEq(fnsLen, getAllExtensions[0].functions.length);

            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extension.functions[j].functionSelector, getAllExtensions[0].functions[j].functionSelector);
                assertEq(extension.functions[j].functionSignature, getAllExtensions[0].functions[j].functionSignature);
            }

            // getExtension
            Extension memory getExtension = extensionRegistry.getExtension(extension.metadata.name);
            assertEq(extension.metadata.implementation, getExtension.metadata.implementation);
            assertEq(extension.metadata.name, getExtension.metadata.name);
            assertEq(extension.metadata.metadataURI, getExtension.metadata.metadataURI);
            assertEq(fnsLen, getExtension.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(getExtension.functions[j].functionSelector, extension.functions[j].functionSelector);
                assertEq(getExtension.functions[j].functionSignature, extension.functions[j].functionSignature);
            }
        }
        {
            string memory name = extension.metadata.name;
            ExtensionFunction[] memory functions = extensionRegistry.getAllFunctionsOfExtension(name);
            uint256 fnsLen = extension.functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extension.functions[j].functionSelector, functions[j].functionSelector);
                assertEq(extension.functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        {
            ExtensionMetadata memory metadata = extension.metadata;
            ExtensionFunction[] memory functions = extension.functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                ExtensionMetadata memory extensionForFunction = extensionRegistry.getExtensionForFunction(
                    functions[j].functionSelector
                );
                assertEq(extensionForFunction.implementation, metadata.implementation);
                assertEq(extensionForFunction.name, metadata.name);
                assertEq(extensionForFunction.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, extensionRegistry.getExtensionImplementation(metadata.name));
        }
    }

    function test_state_updateExtension_allNewFunctions() external {
        _setUp_updateExtension();

        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extension);

        {
            Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
            assertEq(getAllExtensions.length, 1);

            // getAllExtensions
            assertEq(getAllExtensions[0].metadata.implementation, extension.metadata.implementation);
            assertEq(getAllExtensions[0].metadata.name, extension.metadata.name);
            assertEq(getAllExtensions[0].metadata.metadataURI, extension.metadata.metadataURI);
            uint256 fnsLen = extension.functions.length;

            assertEq(fnsLen, 1);
            assertEq(fnsLen, getAllExtensions[0].functions.length);

            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extension.functions[j].functionSelector, getAllExtensions[0].functions[j].functionSelector);
                assertEq(extension.functions[j].functionSignature, getAllExtensions[0].functions[j].functionSignature);
            }

            // getExtension
            Extension memory getExtension = extensionRegistry.getExtension(extension.metadata.name);
            assertEq(extension.metadata.implementation, getExtension.metadata.implementation);
            assertEq(extension.metadata.name, getExtension.metadata.name);
            assertEq(extension.metadata.metadataURI, getExtension.metadata.metadataURI);
            assertEq(fnsLen, getExtension.functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(getExtension.functions[j].functionSelector, extension.functions[j].functionSelector);
                assertEq(getExtension.functions[j].functionSignature, extension.functions[j].functionSignature);
            }
        }
        {
            string memory name = extension.metadata.name;
            ExtensionFunction[] memory functions = extensionRegistry.getAllFunctionsOfExtension(name);
            uint256 fnsLen = extension.functions.length;
            assertEq(fnsLen, functions.length);
            for (uint256 j = 0; j < fnsLen; j += 1) {
                assertEq(extension.functions[j].functionSelector, functions[j].functionSelector);
                assertEq(extension.functions[j].functionSignature, functions[j].functionSignature);
            }
        }
        {
            ExtensionMetadata memory metadata = extension.metadata;
            ExtensionFunction[] memory functions = extension.functions;
            for (uint256 j = 0; j < functions.length; j += 1) {
                ExtensionMetadata memory extensionForFunction = extensionRegistry.getExtensionForFunction(
                    functions[j].functionSelector
                );
                assertEq(extensionForFunction.implementation, metadata.implementation);
                assertEq(extensionForFunction.name, metadata.name);
                assertEq(extensionForFunction.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, extensionRegistry.getExtensionImplementation(metadata.name));
        }
    }

    function test_revert_updateExtension_unauthorizedCaller() external {
        _setUp_updateExtension();

        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert();
        extensionRegistry.updateExtension(extension);
    }

    function test_revert_updateExtension_extensionDoesNotExist() external {
        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert("ExtensionState: extension does not exist.");
        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extension);
    }

    function test_revert_updateExtension_notUpdatingImplementation() external {
        _setUp_updateExtension();

        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: extensionRegistry.getExtensionImplementation("MockERC20")
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.expectRevert("ExtensionState: re-adding same extension.");
        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extension);
    }

    function test_revert_updateExtension_fnSelectorSignatureMismatch() external {
        _setUp_updateExtension();

        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "hello(address,uint256)");

        vm.expectRevert("ExtensionState: fn selector and signature mismatch.");
        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extension);
    }

    /*///////////////////////////////////////////////////////////////
                            Removing extensions
    //////////////////////////////////////////////////////////////*/

    function _setUp_removeExtension() internal {
        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](2);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");
        extension.functions[1] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

        vm.prank(registryDeployer);
        extensionRegistry.addExtension(extension);
    }

    function test_state_removeExtension() external {
        _setUp_removeExtension();

        string memory name = "MockERC20";

        assertEq(true, extensionRegistry.getExtension(name).metadata.implementation != address(0));

        vm.prank(registryDeployer);
        extensionRegistry.removeExtension(name);

        vm.expectRevert("ExtensionRegistry: extension does not exist.");
        extensionRegistry.getExtension(name);

        vm.expectRevert("ExtensionRegistry: no extension for function.");
        extensionRegistry.getExtensionForFunction(MockERC20.mint.selector);

        vm.expectRevert("ExtensionRegistry: no extension for function.");
        extensionRegistry.getExtensionForFunction(MockERC20.toggleTax.selector);

        // Re-add extension with 1 less function (to check if the info for the other function got deleted.)
        Extension memory extension;

        extension.metadata = ExtensionMetadata({
            name: "MockERC20",
            metadataURI: "ipfs://MockERC20",
            implementation: address(new MockERC20())
        });

        extension.functions = new ExtensionFunction[](1);
        extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

        vm.prank(registryDeployer);
        extensionRegistry.addExtension(extension);

        vm.expectRevert("ExtensionRegistry: no extension for function.");
        extensionRegistry.getExtensionForFunction(MockERC20.toggleTax.selector);

        ExtensionFunction[] memory functions = extensionRegistry.getAllFunctionsOfExtension(name);
        assertEq(functions.length, 1);
        assertEq(functions[0].functionSelector, MockERC20.mint.selector);
    }

    function test_revert_removeExtension_unauthorizedCaller() external {
        _setUp_removeExtension();

        string memory name = "MockERC20";

        vm.expectRevert();
        extensionRegistry.removeExtension(name);
    }

    function test_revert_removeExtension_extensionDoesNotExist() external {
        string memory name = "MockERC20";

        vm.prank(registryDeployer);
        vm.expectRevert("ExtensionState: extension does not exist.");
        extensionRegistry.removeExtension(name);
    }
}
