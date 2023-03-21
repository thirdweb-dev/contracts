// // SPDX-License-Identifier: Apache-2.0
// pragma solidity ^0.8.0;

// import "lib/dynamic-contracts/src/interface/IExtension.sol";
// import "lib/dynamic-contracts/src/interface/IRouter.sol";
// import "contracts/dynamic-contracts/ExtensionRegistry.sol";
// import "contracts/dynamic-contracts/interface/IExtensionRegistrySig.sol";
// import { BaseTest } from "../utils/BaseTest.sol";

// import { MockERC20 } from "../mocks/MockERC20.sol";
// import { MockERC721 } from "../mocks/MockERC721.sol";

// contract ContractA {
//     uint256 private a_;

//     function a() external {
//         a_ += 1;
//     }
// }

// contract ContractB {
//     uint256 private b_;

//     function b() external {
//         b_ += 1;
//     }
// }

// contract ContractC {
//     uint256 private c_;

//     function c() external {
//         c_ += 1;
//     }

//     function getC() external view returns (uint256) {
//         return c_;
//     }
// }

// contract ExtensionRegistryTest is BaseTest, IExtension {
//     address private registryDeployer;

//     ExtensionRegistry private extensionRegistry;

//     mapping(uint256 => Extension) private extensions;

//     function setUp() public override {
//         super.setUp();

//         registryDeployer = address(0x123);

//         vm.prank(registryDeployer);
//         extensionRegistry = new ExtensionRegistry(registryDeployer);

//         // Add extension 1.

//         extensions[0].metadata = ExtensionMetadata({
//             name: "ContractA",
//             metadataURI: "ipfs://ContractA",
//             implementation: address(new ContractA())
//         });

//         extensions[0].functions.push(ExtensionFunction(ContractA.a.selector, "a()"));

//         // Add extension 2.

//         extensions[1].metadata = ExtensionMetadata({
//             name: "ContractB",
//             metadataURI: "ipfs://ContractB",
//             implementation: address(new ContractB())
//         });
//         extensions[1].functions.push(ExtensionFunction(ContractB.b.selector, "b()"));

//         // Add extension 3.

//         extensions[2].metadata = ExtensionMetadata({
//             name: "ContractC",
//             metadataURI: "ipfs://ContractC",
//             implementation: address(new ContractC())
//         });
//         extensions[2].functions.push(ExtensionFunction(ContractC.c.selector, "c()"));
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Adding extensions
//     //////////////////////////////////////////////////////////////*/

//     // ======================= Unit tests ==========================

//     function test_state_addExtension() external {
//         uint256 len = 3;

//         for (uint256 i = 0; i < len; i += 1) {
//             vm.prank(registryDeployer);
//             extensionRegistry.addExtension(extensions[i]);
//         }
//         Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();

//         for (uint256 i = 0; i < len; i += 1) {
//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, extensions[i].metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
//             uint256 fnsLen = extensions[i].functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(
//                     extensions[i].functions[j].functionSelector,
//                     getAllExtensions[i].functions[j].functionSelector
//                 );
//                 assertEq(
//                     extensions[i].functions[j].functionSignature,
//                     getAllExtensions[i].functions[j].functionSignature
//                 );
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtension(extensions[i].metadata.name);
//             assertEq(extension.metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(extension.metadata.name, extensions[i].metadata.name);
//             assertEq(extension.metadata.metadataURI, extensions[i].metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extensions[i].functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(extensions[i].functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_revert_addExtension_unauthorizedCaller() external {
//         vm.expectRevert();
//         vm.prank(address(0x999));
//         extensionRegistry.addExtension(extensions[0]);
//     }

//     function test_revert_addExtension_emptyName() external {
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: adding extension without name.");
//         extensionRegistry.addExtension(extension1);
//     }

//     function test_revert_addExtension_fnSelectorSignatureMismatch() external {
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "hello()");

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: fn selector and signature mismatch.");
//         extensionRegistry.addExtension(extension1);
//     }

//     function test_revert_addExtension_sameExtensionName() external {
//         // Add extension 1.

//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         // Add extension 2.

//         Extension memory extension2;

//         extension2.metadata = ExtensionMetadata({
//             name: "MockERC20", // same extension name
//             metadataURI: "ipfs://MockERC721",
//             implementation: address(new MockERC721())
//         });

//         extension2.functions = new ExtensionFunction[](1);
//         extension2.functions[0] = ExtensionFunction(MockERC721.mint.selector, "mint(address,uint256)");

//         vm.startPrank(registryDeployer);

//         extensionRegistry.addExtension(extension1);

//         vm.expectRevert("ExtensionRegistryState: extension already exists.");
//         extensionRegistry.addExtension(extension2);

//         vm.stopPrank();
//     }

//     function test_revert_addExtension_emptyExtensionImplementation() external {
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(0)
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: adding extension without implementation.");
//         extensionRegistry.addExtension(extension1);
//     }

//     // ===================== Scenario tests =========================

//     /// @dev Adding two extensions with common function selectors.
//     function test_state_addExtensionsWithSameFunctionSelectors() external {
//         // Add extension 1.

//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         // Add extension 2.

//         Extension memory extension2;

//         extension2.metadata = ExtensionMetadata({
//             name: "MockERC721",
//             metadataURI: "ipfs://MockERC721",
//             implementation: address(new MockERC721())
//         });

//         extension2.functions = new ExtensionFunction[](1);
//         extension2.functions[0] = ExtensionFunction(MockERC721.mint.selector, "mint(address,uint256)");

//         vm.startPrank(registryDeployer);

//         extensionRegistry.addExtension(extension1);
//         extensionRegistry.addExtension(extension2);

//         vm.stopPrank();

//         Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//         assertEq(getAllExtensions.length, 2);

//         for (uint256 i = 0; i < getAllExtensions.length; i += 1) {
//             Extension memory ext = i > 0 ? extension2 : extension1;

//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, ext.metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, ext.metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, ext.metadata.metadataURI);
//             uint256 fnsLen = ext.functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, getAllExtensions[i].functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, getAllExtensions[i].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtension(ext.metadata.name);
//             assertEq(extension.metadata.implementation, ext.metadata.implementation);
//             assertEq(extension.metadata.name, ext.metadata.name);
//             assertEq(extension.metadata.metadataURI, ext.metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Updating extensions
//     //////////////////////////////////////////////////////////////*/

//     // ======================= Unit tests ==========================

//     function _setUp_updateExtension() internal {
//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension);
//     }

//     function test_state_updateExtension_someNewFunctions() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](2);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");
//         extension.functions[1] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);

//         {
//             Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//             assertEq(getAllExtensions.length, 1);

//             // getAllExtensions
//             assertEq(getAllExtensions[0].metadata.implementation, extension.metadata.implementation);
//             assertEq(getAllExtensions[0].metadata.name, extension.metadata.name);
//             assertEq(getAllExtensions[0].metadata.metadataURI, extension.metadata.metadataURI);
//             uint256 fnsLen = extension.functions.length;

//             assertEq(fnsLen, 2);
//             assertEq(fnsLen, getAllExtensions[0].functions.length);

//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extension.functions[j].functionSelector, getAllExtensions[0].functions[j].functionSelector);
//                 assertEq(extension.functions[j].functionSignature, getAllExtensions[0].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory getExtension = extensionRegistry.getExtension(extension.metadata.name);
//             assertEq(extension.metadata.implementation, getExtension.metadata.implementation);
//             assertEq(extension.metadata.name, getExtension.metadata.name);
//             assertEq(extension.metadata.metadataURI, getExtension.metadata.metadataURI);
//             assertEq(fnsLen, getExtension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(getExtension.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(getExtension.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_state_updateExtension_allNewFunctions() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);

//         {
//             Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//             assertEq(getAllExtensions.length, 1);

//             // getAllExtensions
//             assertEq(getAllExtensions[0].metadata.implementation, extension.metadata.implementation);
//             assertEq(getAllExtensions[0].metadata.name, extension.metadata.name);
//             assertEq(getAllExtensions[0].metadata.metadataURI, extension.metadata.metadataURI);
//             uint256 fnsLen = extension.functions.length;

//             assertEq(fnsLen, 1);
//             assertEq(fnsLen, getAllExtensions[0].functions.length);

//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extension.functions[j].functionSelector, getAllExtensions[0].functions[j].functionSelector);
//                 assertEq(extension.functions[j].functionSignature, getAllExtensions[0].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory getExtension = extensionRegistry.getExtension(extension.metadata.name);
//             assertEq(extension.metadata.implementation, getExtension.metadata.implementation);
//             assertEq(extension.metadata.name, getExtension.metadata.name);
//             assertEq(extension.metadata.metadataURI, getExtension.metadata.metadataURI);
//             assertEq(fnsLen, getExtension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(getExtension.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(getExtension.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_revert_updateExtension_unauthorizedCaller() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.expectRevert();
//         extensionRegistry.updateExtension(extension);
//     }

//     function test_revert_updateExtension_extensionDoesNotExist() external {
//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.expectRevert("ExtensionRegistryState: extension does not exist.");
//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);
//     }

//     function test_revert_updateExtension_notUpdatingImplementation() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: extensionRegistry.getExtension("MockERC20").metadata.implementation
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.expectRevert("ExtensionRegistryState: invalid implementation for update.");
//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);
//     }

//     function test_revert_updateExtension_emptyImplementation() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(0)
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.expectRevert("ExtensionRegistryState: invalid implementation for update.");
//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);
//     }

//     function test_revert_updateExtension_fnSelectorSignatureMismatch() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](1);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "hello(address,uint256)");

//         vm.expectRevert("ExtensionRegistryState: fn selector and signature mismatch.");
//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension);
//     }

//     // ===================== Scenario tests =========================

//     function test_state_updateExtension_commonFnsWithAnotherExtension() external {
//         // Add extension 1.

//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         // Add extension 2.

//         Extension memory extension2;

//         extension2.metadata = ExtensionMetadata({
//             name: "MockERC20_2",
//             metadataURI: "ipfs://MockERC20_2",
//             implementation: address(new MockERC20())
//         });

//         extension2.functions = new ExtensionFunction[](1);
//         extension2.functions[0] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

//         vm.startPrank(registryDeployer);

//         extensionRegistry.addExtension(extension1);
//         extensionRegistry.addExtension(extension2);

//         vm.stopPrank();

//         // Update extension 2 to have same `mint` function as extension 1.

//         Extension memory extension2Updated = extension2;
//         extension2Updated.metadata.implementation = address(new MockERC20());
//         extension2Updated.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.updateExtension(extension2Updated);

//         Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//         assertEq(getAllExtensions.length, 2);

//         for (uint256 i = 0; i < getAllExtensions.length; i += 1) {
//             Extension memory ext = getAllExtensions[i].metadata.implementation ==
//                 extension2Updated.metadata.implementation
//                 ? extension2Updated
//                 : extension1;

//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, ext.metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, ext.metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, ext.metadata.metadataURI);
//             uint256 fnsLen = ext.functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, getAllExtensions[i].functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, getAllExtensions[i].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtension(ext.metadata.name);
//             assertEq(extension.metadata.implementation, ext.metadata.implementation);
//             assertEq(extension.metadata.name, ext.metadata.name);
//             assertEq(extension.metadata.metadataURI, ext.metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Removing extensions
//     //////////////////////////////////////////////////////////////*/

//     // ======================= Unit tests ==========================

//     function _setUp_removeExtension() internal {
//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](2);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");
//         extension.functions[1] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension);
//     }

//     function test_state_removeExtension() external {
//         _setUp_removeExtension();

//         string memory name = "MockERC20";

//         assertEq(true, extensionRegistry.getExtension(name).metadata.implementation != address(0));

//         vm.prank(registryDeployer);
//         extensionRegistry.removeExtension(name);

//         vm.expectRevert("ExtensionRegistry: extension does not exist.");
//         extensionRegistry.getExtension(name);
//     }

//     function test_revert_removeExtension_unauthorizedCaller() external {
//         _setUp_removeExtension();

//         string memory name = "MockERC20";

//         vm.expectRevert();
//         extensionRegistry.removeExtension(name);
//     }

//     function test_revert_removeExtension_extensionDoesNotExist() external {
//         string memory name = "MockERC20";

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: extension does not exist.");
//         extensionRegistry.removeExtension(name);

//         _setUp_removeExtension();

//         vm.prank(registryDeployer);
//         extensionRegistry.removeExtension(name);

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: extension does not exist.");
//         extensionRegistry.removeExtension(name);
//     }

//     // ===================== Scenario tests =========================

//     function test_state_removeExtension_reAddingExtension() external {
//         // Add extension 1.

//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         // Add extension 2.

//         Extension memory extension2;

//         extension2.metadata = ExtensionMetadata({
//             name: "MockERC20_2",
//             metadataURI: "ipfs://MockERC20_2",
//             implementation: address(new MockERC20())
//         });

//         extension2.functions = new ExtensionFunction[](1);
//         extension2.functions[0] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

//         vm.startPrank(registryDeployer);

//         extensionRegistry.addExtension(extension1);
//         extensionRegistry.addExtension(extension2);

//         vm.stopPrank();

//         // Remove extension 1.

//         string memory name = extension1.metadata.name;

//         vm.prank(registryDeployer);
//         extensionRegistry.removeExtension(name);

//         vm.expectRevert("ExtensionRegistry: extension does not exist.");
//         extensionRegistry.getExtension(name);

//         Extension[] memory allExtensions = extensionRegistry.getAllExtensions();
//         assertEq(allExtensions.length, 1);
//         assertEq(allExtensions[0].metadata.name, extension2.metadata.name);

//         // Re-add extension 1.
//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension1);

//         Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//         assertEq(getAllExtensions.length, 2);

//         for (uint256 i = 0; i < getAllExtensions.length; i += 1) {
//             Extension memory ext = getAllExtensions[i].metadata.implementation == extension2.metadata.implementation
//                 ? extension2
//                 : extension1;

//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, ext.metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, ext.metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, ext.metadata.metadataURI);
//             uint256 fnsLen = ext.functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, getAllExtensions[i].functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, getAllExtensions[i].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtension(ext.metadata.name);
//             assertEq(extension.metadata.implementation, ext.metadata.implementation);
//             assertEq(extension.metadata.name, ext.metadata.name);
//             assertEq(extension.metadata.metadataURI, ext.metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(ext.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(ext.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Building a snapshot
//     //////////////////////////////////////////////////////////////*/

//     function test_state_buildExtensionSnapshot() external {
//         uint256 len = 3;

//         string[] memory extensionNames = new string[](len);
//         string memory snapshotId = "snapshotId";

//         for (uint256 i = 0; i < len; i += 1) {
//             vm.prank(registryDeployer);
//             extensionRegistry.addExtension(extensions[i]);
//             extensionNames[i] = extensions[i].metadata.name;
//         }

//         // Add first set of extensions to snapshot.
//         vm.prank(registryDeployer);
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, false);

//         string[] memory allSnapshotIds = extensionRegistry.getAllSnapshotIds();
//         assertEq(allSnapshotIds.length, 1);
//         assertEq(allSnapshotIds[0], snapshotId);

//         Extension[] memory snapshotExtensions = extensionRegistry.getExtensionSnapshot(snapshotId);

//         for (uint256 i = 0; i < len; i += 1) {
//             // snapshotExtensions
//             assertEq(snapshotExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(snapshotExtensions[i].metadata.name, extensions[i].metadata.name);
//             assertEq(snapshotExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
//             uint256 fnsLen = extensions[i].functions.length;
//             assertEq(fnsLen, snapshotExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(
//                     extensions[i].functions[j].functionSelector,
//                     snapshotExtensions[i].functions[j].functionSelector
//                 );
//                 assertEq(
//                     extensions[i].functions[j].functionSignature,
//                     snapshotExtensions[i].functions[j].functionSignature
//                 );
//             }
//         }

//         // Add another extension to the same snapshot and freeze it.
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension1);

//         string[] memory newExtensionName = new string[](1);
//         newExtensionName[0] = extension1.metadata.name;

//         vm.prank(registryDeployer);
//         extensionRegistry.buildExtensionSnapshot(snapshotId, newExtensionName, true);

//         allSnapshotIds = extensionRegistry.getAllSnapshotIds();
//         assertEq(allSnapshotIds.length, 1);
//         assertEq(allSnapshotIds[0], snapshotId);

//         snapshotExtensions = extensionRegistry.getExtensionSnapshot(snapshotId);
//         assertEq(snapshotExtensions.length, 4);

//         assertEq(snapshotExtensions[3].metadata.implementation, extension1.metadata.implementation);
//         assertEq(snapshotExtensions[3].metadata.name, extension1.metadata.name);
//         assertEq(snapshotExtensions[3].metadata.metadataURI, extension1.metadata.metadataURI);
//         uint256 fnsLen = extension1.functions.length;
//         assertEq(fnsLen, snapshotExtensions[3].functions.length);
//         for (uint256 j = 0; j < fnsLen; j += 1) {
//             assertEq(extension1.functions[j].functionSelector, snapshotExtensions[3].functions[j].functionSelector);
//             assertEq(extension1.functions[j].functionSignature, snapshotExtensions[3].functions[j].functionSignature);
//         }
//     }

//     function test_revert_buildExtensionSnapshot_unauthorizedCaller() external {
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension1);

//         string memory snapshotId = "snapshotId";
//         string[] memory extensionNames = new string[](1);
//         extensionNames[0] = extension1.metadata.name;

//         vm.prank(address(0x9999));
//         vm.expectRevert();
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true);
//     }

//     function test_revert_buildExtensionSnapshot_emptySnapshotId() external {
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension1);

//         string memory snapshotId = "";
//         string[] memory extensionNames = new string[](1);
//         extensionNames[0] = extension1.metadata.name;

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistry: extension snapshot ID cannot be empty.");
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true);
//     }

//     function test_revert_buildExtensionSnapshot_addingNonexistentExtension() external {
//         string memory snapshotId = "snapshotId";
//         string[] memory extensionNames = new string[](1);
//         extensionNames[0] = "MockERC20";

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: extension does not exist.");
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true);
//     }

//     function test_revert_buildExtensionSnapshot_addingToFrozenSnapshot() external {
//         uint256 len = 3;

//         string[] memory extensionNames = new string[](len);
//         string memory snapshotId = "snapshotId";

//         for (uint256 i = 0; i < len; i += 1) {
//             vm.prank(registryDeployer);
//             extensionRegistry.addExtension(extensions[i]);
//             extensionNames[i] = extensions[i].metadata.name;
//         }

//         // Add first set of extensions to snapshot.
//         vm.prank(registryDeployer);
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true); // freeze

//         // Add another extension to a frozen snapshot.
//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.prank(registryDeployer);
//         extensionRegistry.addExtension(extension1);

//         string[] memory newExtensionName = new string[](1);
//         newExtensionName[0] = extension1.metadata.name;

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: extension snapshot is frozen.");
//         extensionRegistry.buildExtensionSnapshot(snapshotId, newExtensionName, true);
//     }

//     function test_revert_buildExtensionSnapshot_addingExtensionsWithCommonFns() external {
//         // Add extension 1.

//         Extension memory extension1;

//         extension1.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension1.functions = new ExtensionFunction[](1);
//         extension1.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         // Add extension 2.

//         Extension memory extension2;

//         extension2.metadata = ExtensionMetadata({
//             name: "MockERC20_2",
//             metadataURI: "ipfs://MockERC20_2",
//             implementation: address(new MockERC20())
//         });

//         extension2.functions = new ExtensionFunction[](1);
//         extension2.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");

//         vm.startPrank(registryDeployer);

//         extensionRegistry.addExtension(extension1);
//         extensionRegistry.addExtension(extension2);

//         vm.stopPrank();

//         // Add extensions to snapshot.
//         string memory snapshotId = "snapshotId";
//         string[] memory extensionNames = new string[](2);
//         extensionNames[0] = extension1.metadata.name;
//         extensionNames[1] = extension2.metadata.name;

//         vm.prank(registryDeployer);
//         vm.expectRevert("ExtensionRegistryState: function already exists in snapshot.");
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true);
//     }

//     /*///////////////////////////////////////////////////////////////
//                         Registering with snapshot
//     //////////////////////////////////////////////////////////////*/

//     address private router;
//     string private snapshotId = "snapshotId";

//     function _setUp_registerWithSnapshot() internal {
//         router = address(0x1234);

//         uint256 len = 3;

//         string[] memory extensionNames = new string[](len);
//         snapshotId = "snapshotId";

//         for (uint256 i = 0; i < len; i += 1) {
//             vm.prank(registryDeployer);
//             extensionRegistry.addExtension(extensions[i]);
//             extensionNames[i] = extensions[i].metadata.name;
//         }

//         // Add first set of extensions to snapshot.
//         vm.prank(registryDeployer);
//         extensionRegistry.buildExtensionSnapshot(snapshotId, extensionNames, true);
//     }

//     function test_state_registerWithSnapshot() external {
//         _setUp_registerWithSnapshot();

//         // Register router with snapshot.
//         vm.prank(router);
//         extensionRegistry.registerWithSnapshot(snapshotId);

//         Extension[] memory getAllExtensions = extensionRegistry.getSnapshotForRouter(router);

//         uint256 len = 3;
//         for (uint256 i = 0; i < len; i += 1) {
//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, extensions[i].metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
//             uint256 fnsLen = extensions[i].functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(
//                     extensions[i].functions[j].functionSelector,
//                     getAllExtensions[i].functions[j].functionSelector
//                 );
//                 assertEq(
//                     extensions[i].functions[j].functionSignature,
//                     getAllExtensions[i].functions[j].functionSignature
//                 );

//                 ExtensionMetadata memory metadata = extensionRegistry.getExtensionForRouterFunction(
//                     extensions[i].functions[j].functionSelector,
//                     router
//                 );

//                 assertEq(metadata.implementation, extensions[i].metadata.implementation);
//                 assertEq(metadata.name, extensions[i].metadata.name);
//                 assertEq(metadata.metadataURI, extensions[i].metadata.metadataURI);
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtensionForRouter(extensions[i].metadata.name, router);
//             assertEq(extension.metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(extension.metadata.name, extensions[i].metadata.name);
//             assertEq(extension.metadata.metadataURI, extensions[i].metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extensions[i].functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(extensions[i].functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_revert_registerWithSnapshot_nonexistentSnapshotId() external {
//         router = address(0x1234);

//         // Register router with snapshot when snapshot does not exist.
//         vm.prank(router);
//         vm.expectRevert("ExtensionRegistryState: extension snapshot does not exist.");
//         extensionRegistry.registerWithSnapshot(snapshotId);
//     }

//     function test_revert_registerWithSnapshot_routerAlreadyRegistered() external {
//         _setUp_registerWithSnapshot();

//         // Register router with snapshot.
//         vm.prank(router);
//         extensionRegistry.registerWithSnapshot(snapshotId);

//         vm.prank(router);
//         vm.expectRevert("ExtensionRegistryState: router already registered.");
//         extensionRegistry.registerWithSnapshot(snapshotId);
//     }

//     /*///////////////////////////////////////////////////////////////
//                             Signature actions
//     //////////////////////////////////////////////////////////////*/

//     address private authorizedSigner;
//     bytes private extensionUpdateRequestSig;
//     IExtensionRegistrySig.ExtensionUpdateRequest private request;

//     function _setUp_sig(address _caller, IExtensionRegistrySig.ExtensionUpdateType _updateType) internal {
//         uint256 privateKey = 123456;
//         authorizedSigner = vm.addr(privateKey);

//         vm.prank(registryDeployer);
//         extensionRegistry.grantRole(0x00, authorizedSigner);

//         request.caller = _caller;
//         request.updateType = _updateType;
//         request.uid = keccak256("uid");
//         request.validityStartTimestamp = uint128(0);
//         request.validityEndTimestamp = uint128(100);

//         bytes32 typehash = keccak256(
//             "ExtensionUpdateRequest(address caller,uint256 updateType,bytes32 uid,uint128 validityStartTimestamp,uint128 validityEndTimestamp)"
//         );
//         bytes32 nameHash = keccak256(bytes("ExtensionRegistry"));
//         bytes32 versionHash = keccak256(bytes("1"));
//         bytes32 typehashEip712 = keccak256(
//             "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
//         );
//         bytes32 domainSeparator = keccak256(
//             abi.encode(typehashEip712, nameHash, versionHash, block.chainid, address(extensionRegistry))
//         );

//         bytes memory encodedRequest = abi.encode(
//             typehash,
//             request.caller,
//             request.updateType,
//             request.uid,
//             request.validityStartTimestamp,
//             request.validityEndTimestamp
//         );

//         bytes32 structHash = keccak256(encodedRequest);
//         bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
//         extensionUpdateRequestSig = abi.encodePacked(r, s, v);
//     }

//     function test_state_addExtensionWithSig() external {
//         address caller = address(0x12345);

//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Add);

//         vm.prank(caller);
//         extensionRegistry.addExtensionWithSig(extensions[0], request, extensionUpdateRequestSig);

//         Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//         uint256 len = getAllExtensions.length;

//         for (uint256 i = 0; i < len; i += 1) {
//             // getAllExtensions
//             assertEq(getAllExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(getAllExtensions[i].metadata.name, extensions[i].metadata.name);
//             assertEq(getAllExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
//             uint256 fnsLen = extensions[i].functions.length;
//             assertEq(fnsLen, getAllExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(
//                     extensions[i].functions[j].functionSelector,
//                     getAllExtensions[i].functions[j].functionSelector
//                 );
//                 assertEq(
//                     extensions[i].functions[j].functionSignature,
//                     getAllExtensions[i].functions[j].functionSignature
//                 );
//             }

//             // getExtension
//             Extension memory extension = extensionRegistry.getExtension(extensions[i].metadata.name);
//             assertEq(extension.metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(extension.metadata.name, extensions[i].metadata.name);
//             assertEq(extension.metadata.metadataURI, extensions[i].metadata.metadataURI);
//             assertEq(fnsLen, extension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extensions[i].functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(extensions[i].functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_state_updateExtensionWithSig() external {
//         _setUp_updateExtension();

//         Extension memory extension;

//         extension.metadata = ExtensionMetadata({
//             name: "MockERC20",
//             metadataURI: "ipfs://MockERC20",
//             implementation: address(new MockERC20())
//         });

//         extension.functions = new ExtensionFunction[](2);
//         extension.functions[0] = ExtensionFunction(MockERC20.mint.selector, "mint(address,uint256)");
//         extension.functions[1] = ExtensionFunction(MockERC20.toggleTax.selector, "toggleTax()");

//         address caller = address(0x12345);

//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Update);

//         vm.prank(caller);
//         extensionRegistry.updateExtensionWithSig(extension, request, extensionUpdateRequestSig);

//         {
//             Extension[] memory getAllExtensions = extensionRegistry.getAllExtensions();
//             assertEq(getAllExtensions.length, 1);

//             // getAllExtensions
//             assertEq(getAllExtensions[0].metadata.implementation, extension.metadata.implementation);
//             assertEq(getAllExtensions[0].metadata.name, extension.metadata.name);
//             assertEq(getAllExtensions[0].metadata.metadataURI, extension.metadata.metadataURI);
//             uint256 fnsLen = extension.functions.length;

//             assertEq(fnsLen, 2);
//             assertEq(fnsLen, getAllExtensions[0].functions.length);

//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(extension.functions[j].functionSelector, getAllExtensions[0].functions[j].functionSelector);
//                 assertEq(extension.functions[j].functionSignature, getAllExtensions[0].functions[j].functionSignature);
//             }

//             // getExtension
//             Extension memory getExtension = extensionRegistry.getExtension(extension.metadata.name);
//             assertEq(extension.metadata.implementation, getExtension.metadata.implementation);
//             assertEq(extension.metadata.name, getExtension.metadata.name);
//             assertEq(extension.metadata.metadataURI, getExtension.metadata.metadataURI);
//             assertEq(fnsLen, getExtension.functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(getExtension.functions[j].functionSelector, extension.functions[j].functionSelector);
//                 assertEq(getExtension.functions[j].functionSignature, extension.functions[j].functionSignature);
//             }
//         }
//     }

//     function test_state_removeExtensionWithSig() external {
//         _setUp_removeExtension();

//         string memory name = "MockERC20";

//         assertEq(true, extensionRegistry.getExtension(name).metadata.implementation != address(0));

//         address caller = address(0x12345);

//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Remove);

//         vm.prank(caller);
//         extensionRegistry.removeExtensionWithSig(name, request, extensionUpdateRequestSig);

//         vm.expectRevert("ExtensionRegistry: extension does not exist.");
//         extensionRegistry.getExtension(name);
//     }

//     function test_state_buildExtensionSnapshotWithSig() external {
//         uint256 len = 3;

//         string[] memory extensionNames = new string[](len);
//         string memory snapshotId = "snapshotId";

//         for (uint256 i = 0; i < len; i += 1) {
//             vm.prank(registryDeployer);
//             extensionRegistry.addExtension(extensions[i]);
//             extensionNames[i] = extensions[i].metadata.name;
//         }

//         // Add first set of extensions to snapshot.
//         address caller = address(0x12345);

//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Build);

//         vm.prank(caller);
//         extensionRegistry.buildExtensionSnapshotWithSig(
//             snapshotId,
//             extensionNames,
//             true,
//             request,
//             extensionUpdateRequestSig
//         );

//         string[] memory allSnapshotIds = extensionRegistry.getAllSnapshotIds();
//         assertEq(allSnapshotIds.length, 1);
//         assertEq(allSnapshotIds[0], snapshotId);

//         Extension[] memory snapshotExtensions = extensionRegistry.getExtensionSnapshot(snapshotId);

//         for (uint256 i = 0; i < len; i += 1) {
//             // snapshotExtensions
//             assertEq(snapshotExtensions[i].metadata.implementation, extensions[i].metadata.implementation);
//             assertEq(snapshotExtensions[i].metadata.name, extensions[i].metadata.name);
//             assertEq(snapshotExtensions[i].metadata.metadataURI, extensions[i].metadata.metadataURI);
//             uint256 fnsLen = extensions[i].functions.length;
//             assertEq(fnsLen, snapshotExtensions[i].functions.length);
//             for (uint256 j = 0; j < fnsLen; j += 1) {
//                 assertEq(
//                     extensions[i].functions[j].functionSelector,
//                     snapshotExtensions[i].functions[j].functionSelector
//                 );
//                 assertEq(
//                     extensions[i].functions[j].functionSignature,
//                     snapshotExtensions[i].functions[j].functionSignature
//                 );
//             }
//         }
//     }

//     function test_revert_onlyValidRequest_unauthorizedSigner() external {
//         address caller = address(0x12345);
//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Add);

//         vm.prank(registryDeployer);
//         extensionRegistry.revokeRole(0x00, authorizedSigner);

//         vm.prank(caller);
//         vm.expectRevert("ExtensionRegistrySig: invalid request.");
//         extensionRegistry.addExtensionWithSig(extensions[0], request, extensionUpdateRequestSig);
//     }

//     function test_revert_onlyValidRequest_unauthorizedCaller() external {
//         address caller = address(0x12345);
//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Add);

//         vm.prank(address(0x456));
//         vm.expectRevert("ExtensionRegistry: unauthorized caller.");
//         extensionRegistry.addExtensionWithSig(extensions[0], request, extensionUpdateRequestSig);
//     }

//     function test_revert_onlyValidRequest_requestExpired() external {
//         address caller = address(0x12345);
//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Add);

//         vm.warp(request.validityEndTimestamp + 1);

//         vm.prank(caller);
//         vm.expectRevert("ExtensionRegistrySig: request expired.");
//         extensionRegistry.addExtensionWithSig(extensions[0], request, extensionUpdateRequestSig);
//     }

//     function test_revert_onlyValidRequest_invalidUpdateType() external {
//         address caller = address(0x12345);
//         _setUp_sig(caller, IExtensionRegistrySig.ExtensionUpdateType.Remove);

//         vm.prank(caller);
//         vm.expectRevert("ExtensionRegistry: invalid update type.");
//         extensionRegistry.addExtensionWithSig(extensions[0], request, extensionUpdateRequestSig);
//     }
// }
