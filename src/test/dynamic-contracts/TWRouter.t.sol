// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/interface/IExtension.sol";
import "contracts/dynamic-contracts/ExtensionRegistry.sol";
import "contracts/dynamic-contracts/TWRouter.sol";

import { BaseTest } from "../utils/BaseTest.sol";
import { TWProxy } from "contracts/TWProxy.sol";

contract TWRouterImplementation is TWRouter {
    constructor(address _extensionRegistry, string[] memory _extensionNames)
        TWRouter(_extensionRegistry, _extensionNames)
    {}

    function _canSetExtension() internal view virtual override returns (bool) {
        return true;
    }
}

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

contract ContractD {
    uint256 private d_;

    function d() external {
        d_ += 1;
    }

    function getD() external view returns (uint256) {
        return d_;
    }
}

contract TWRouterTest is BaseTest, IExtension {
    address private router;
    address private registryDeployer;

    ExtensionRegistry private extensionRegistry;

    mapping(uint256 => Extension) private extensions;

    function _setupExtensions() private returns (string[] memory extensionNames) {
        extensionNames = new string[](3);

        // Add extension 1.

        extensions[0].metadata = ExtensionMetadata({
            name: "ContractA",
            metadataURI: "ipfs://ContractA",
            implementation: address(new ContractA())
        });

        extensions[0].functions.push(ExtensionFunction(ContractA.a.selector, "a()"));

        extensionNames[0] = extensions[0].metadata.name;

        // Add extension 2.

        extensions[1].metadata = ExtensionMetadata({
            name: "ContractB",
            metadataURI: "ipfs://ContractB",
            implementation: address(new ContractB())
        });
        extensions[1].functions.push(ExtensionFunction(ContractB.b.selector, "b()"));

        extensionNames[1] = extensions[1].metadata.name;

        // Add extension 3.

        extensions[2].metadata = ExtensionMetadata({
            name: "ContractC",
            metadataURI: "ipfs://ContractC",
            implementation: address(new ContractC())
        });
        extensions[2].functions.push(ExtensionFunction(ContractC.c.selector, "c()"));
        extensions[2].functions.push(ExtensionFunction(ContractC.getC.selector, "getC()"));

        extensionNames[2] = extensions[2].metadata.name;
    }

    function setUp() public override {
        super.setUp();

        // Set up extension registry.
        registryDeployer = address(0x123);

        vm.prank(registryDeployer);
        extensionRegistry = new ExtensionRegistry(registryDeployer);

        // Set up extensions
        string[] memory extensionNames = _setupExtensions();
        uint256 len = extensionNames.length;

        for (uint256 i = 0; i < len; i += 1) {
            vm.prank(registryDeployer);
            extensionRegistry.addExtension(extensions[i]);
        }

        // Deploy TWRouter implementation
        address routerImpl = address(new TWRouterImplementation(address(extensionRegistry), extensionNames));

        // Deploy proxy to router.
        router = address(new TWProxy(routerImpl, ""));
    }

    // ==================== Initial state ====================

    function test_state_initialState() external {
        TWRouter twRouter = TWRouter(payable(router));

        Extension[] memory getAllExtensions = twRouter.getAllExtensions();
        uint256 len = 3;

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
            Extension memory extension = twRouter.getExtension(extensions[i].metadata.name);
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
            ExtensionFunction[] memory functions = twRouter.getAllFunctionsOfExtension(name);
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
                ExtensionMetadata memory extension = twRouter.getExtensionForFunction(functions[j].functionSelector);
                assertEq(extension.implementation, metadata.implementation);
                assertEq(extension.name, metadata.name);
                assertEq(extension.metadataURI, metadata.metadataURI);
            }
            assertEq(metadata.implementation, twRouter.getExtensionImplementation(metadata.name));
        }

        // Test contract call
        uint256 cBefore = ContractC(router).getC();
        ContractC(router).c();

        assertEq(cBefore + 1, ContractC(router).getC());
    }

    // ==================== Add extensions ====================

    function _setupAddExtension() private {
        // Add new extension to registry

        extensions[3].metadata = ExtensionMetadata({
            name: "ContractD",
            metadataURI: "ipfs://ContractD",
            implementation: address(new ContractD())
        });
        extensions[3].functions.push(ExtensionFunction(ContractD.d.selector, "d()"));
        extensions[3].functions.push(ExtensionFunction(ContractD.getD.selector, "getD()"));

        vm.prank(registryDeployer);
        extensionRegistry.addExtension(extensions[3]);
    }

    function test_state_addExtension() external {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addExtension(extensions[3].metadata.name);

        // getExtension
        Extension memory extension = twRouter.getExtension(extensions[3].metadata.name);
        assertEq(extension.metadata.implementation, extensions[3].metadata.implementation);
        assertEq(extension.metadata.name, extensions[3].metadata.name);
        assertEq(extension.metadata.metadataURI, extensions[3].metadata.metadataURI);
        uint256 fnsLen = extensions[3].functions.length;
        assertEq(fnsLen, extension.functions.length);
        for (uint256 j = 0; j < fnsLen; j += 1) {
            assertEq(extensions[3].functions[j].functionSelector, extension.functions[j].functionSelector);
            assertEq(extensions[3].functions[j].functionSignature, extension.functions[j].functionSignature);
        }
    }

    function test_revert_addExtension_extensionDNE() external {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("ExtensionRegistry: extension does not exist.");
        twRouter.addExtension("Random name");
    }

    function test_revert_addExtension_extensionAlreadyExists() external {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addExtension(extensions[3].metadata.name);

        vm.expectRevert("ExtensionState: extension already exists.");
        twRouter.addExtension(extensions[3].metadata.name);
    }

    // ==================== Update extensions ====================

    function _setupUpdateExtension() private {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addExtension(extensions[3].metadata.name);

        // Update extension to registry
        extensions[3].metadata.implementation = address(new ContractD());

        vm.prank(registryDeployer);
        extensionRegistry.updateExtension(extensions[3]);
    }

    function test_state_updateExtension() external {
        _setupUpdateExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.updateExtension(extensions[3].metadata.name);

        // getExtension
        Extension memory extension = twRouter.getExtension(extensions[3].metadata.name);
        assertEq(extension.metadata.implementation, extensions[3].metadata.implementation);
        assertEq(extension.metadata.name, extensions[3].metadata.name);
        assertEq(extension.metadata.metadataURI, extensions[3].metadata.metadataURI);
        uint256 fnsLen = extensions[3].functions.length;
        assertEq(fnsLen, extension.functions.length);
        for (uint256 j = 0; j < fnsLen; j += 1) {
            assertEq(extensions[3].functions[j].functionSelector, extension.functions[j].functionSelector);
            assertEq(extensions[3].functions[j].functionSignature, extension.functions[j].functionSignature);
        }
    }

    function test_revert_updateExtension_extensionDNE_inRegistry() external {
        _setupUpdateExtension();

        vm.prank(registryDeployer);
        extensionRegistry.removeExtension(extensions[3].metadata.name);

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("ExtensionRegistry: extension does not exist.");
        twRouter.updateExtension(extensions[3].metadata.name);
    }

    function test_revert_updateExtension_extensionDNE_inRouter() external {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("ExtensionState: extension does not exist.");
        twRouter.updateExtension(extensions[3].metadata.name);
    }

    function test_revert_updateExtension_reAddingExtension() external {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addExtension(extensions[3].metadata.name);

        vm.expectRevert("ExtensionState: re-adding same extension.");
        twRouter.updateExtension(extensions[3].metadata.name);
    }

    // ==================== Remove extensions ====================

    function _setupRemoveExtension() private {
        _setupAddExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.addExtension(extensions[3].metadata.name);
    }

    function test_state_removeExtension() external {
        _setupRemoveExtension();

        TWRouter twRouter = TWRouter((payable(router)));
        twRouter.removeExtension(extensions[3].metadata.name);

        vm.expectRevert("DefaultExtensionSet: extension does not exist.");
        twRouter.getExtension(extensions[3].metadata.name);
    }

    function test_revert_removeExtension_extensionDNE() external {
        TWRouter twRouter = TWRouter((payable(router)));

        vm.expectRevert("ExtensionState: extension does not exist.");
        twRouter.removeExtension("Random name");
    }
}
