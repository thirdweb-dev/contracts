// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import { ContractPublisher } from "contracts/infra/ContractPublisher.sol";
import "contracts/infra/interface/IContractPublisher.sol";
import "contracts/infra/TWRegistry.sol";

// Test helpers
import { BaseTest, MockContractPublisher } from "./utils/BaseTest.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract MockCustomContract {
    uint256 public num;

    constructor(uint256 _num) {
        num = _num;
    }
}

contract IContractPublisherData {
    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a publisher's approval of an operator is updated.
    event Approved(address indexed publisher, address indexed operator, bool isApproved);

    /// @dev Emitted when a contract is published.
    event ContractPublished(
        address indexed operator,
        address indexed publisher,
        IContractPublisher.CustomContractInstance publishedContract
    );

    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is added to the public list.
    event AddedContractToPublicList(address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is removed from the public list.
    event RemovedContractToPublicList(address indexed publisher, string indexed contractId);
}

contract ContractPublisherTest is BaseTest, IContractPublisherData {
    ContractPublisher internal byoc;
    TWRegistry internal twRegistry;

    address internal publisher;
    address internal operator;
    address internal deployerOfPublished;

    string internal publishMetadataUri = "ipfs://QmeXyz";
    string internal compilerMetadataUri = "ipfs://QmeXyz";

    function setUp() public override {
        super.setUp();

        byoc = ContractPublisher(contractPublisher);
        twRegistry = TWRegistry(registry);

        publisher = getActor(0);
        operator = getActor(1);
        deployerOfPublished = getActor(2);
    }

    function test_publish() public {
        string memory contractId = "MyContract";
        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        IContractPublisher.CustomContractInstance memory customContract = byoc.getPublishedContract(
            publisher,
            contractId
        );

        assertEq(customContract.contractId, contractId);
        assertEq(customContract.publishMetadataUri, publishMetadataUri);
        assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
        assertEq(customContract.implementation, address(0));
    }

    // Deprecated
    // function test_publish_viaOperator() public {
    //     string memory contractId = "MyContract";

    //     vm.prank(publisher);
    //     byoc.approveOperator(operator, true);

    //     vm.prank(operator);
    //     byoc.publishContract(
    //         publisher,
    //         publishMetadataUri,
    //         keccak256(type(MockCustomContract).creationCode),
    //         address(0),
    //         contractId
    //     );

    //     IContractPublisher.CustomContractInstance memory customContract = byoc.getPublishedContract(
    //         publisher,
    //         contractId
    //     );

    //     assertEq(customContract.contractId, contractId);
    //     assertEq(customContract.publishMetadataUri, publishMetadataUri);
    //     assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
    //     assertEq(customContract.implementation, address(0));
    // }

    function test_state_setPrevPublisher() public {
        // === when prevPublisher address is address(0)
        vm.prank(factoryAdmin);
        byoc.setPrevPublisher(IContractPublisher(address(0)));

        assertEq(byoc.getAllPublishedContracts(publisher).length, 0);
        assertEq(address(byoc.prevPublisher()), address(0));

        string memory contractId = "MyContract";
        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
        IContractPublisher.CustomContractInstance[] memory contracts = byoc.getAllPublishedContracts(publisher);
        assertEq(contracts.length, 1);
        assertEq(contracts[0].contractId, "MyContract");

        // === when prevPublisher address is set to MockPublisher
        address mock = address(new MockContractPublisher());
        vm.prank(factoryAdmin);
        byoc.setPrevPublisher(IContractPublisher(mock));

        contracts = byoc.getAllPublishedContracts(publisher);
        assertEq(contracts.length, 2);
        assertEq(address(byoc.prevPublisher()), mock);
        assertEq(contracts[0].contractId, "MockContract");
        assertEq(contracts[1].contractId, "MyContract");
    }

    function test_revert_setPrevPublisher() public {
        vm.expectRevert("Not authorized");
        byoc.setPrevPublisher(IContractPublisher(address(0)));
    }

    function test_state_setPublisherProfileUri() public {
        address user = address(0x123);
        string memory uriOne = "ipfs://one";
        string memory uriTwo = "ipfs://two";

        // user updating for self
        vm.prank(user);
        byoc.setPublisherProfileUri(user, uriOne);
        assertEq(byoc.getPublisherProfileUri(user), uriOne);

        // random caller
        vm.prank(address(0x345));
        vm.expectRevert("Registry paused or caller not authorized");
        byoc.setPublisherProfileUri(user, uriOne);

        // MIGRATION_ROLE holder updating for a user
        vm.prank(factoryAdmin);
        byoc.setPublisherProfileUri(user, uriTwo);
        assertEq(byoc.getPublisherProfileUri(user), uriTwo);
    }

    function test_state_setPublisherProfileUri_whenPaused() public {
        vm.prank(factoryAdmin);
        byoc.setPause(true);
        address user = address(0x123);
        string memory uriOne = "ipfs://one";
        string memory uriTwo = "ipfs://two";

        // user updating for self
        vm.prank(user);
        vm.expectRevert("Registry paused or caller not authorized");
        byoc.setPublisherProfileUri(user, uriOne);

        // MIGRATION_ROLE holder updating for a user
        vm.prank(factoryAdmin);
        byoc.setPublisherProfileUri(user, uriTwo);
        assertEq(byoc.getPublisherProfileUri(user), uriTwo);
    }

    function test_publish_revert_unapprovedCaller() public {
        string memory contractId = "MyContract";

        vm.expectRevert("unapproved caller");

        vm.prank(operator);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
    }

    function test_publish_revert_registryPaused() public {
        string memory contractId = "MyContract";

        vm.prank(factoryAdmin);
        byoc.setPause(true);

        vm.expectRevert("registry paused");

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
    }

    function test_publish_multiple_versions() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
        string[] memory resolved = byoc.getPublishedUriFromCompilerUri(compilerMetadataUri);
        assertEq(resolved.length, 1);
        assertEq(resolved[0], publishMetadataUri);

        string memory otherUri = "ipfs://abcd";
        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            otherUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        string[] memory resolved2 = byoc.getPublishedUriFromCompilerUri(otherUri);
        assertEq(resolved2.length, 1);
        assertEq(resolved2[0], publishMetadataUri);
    }

    function test_read_from_linked_publisher() public {
        IContractPublisher.CustomContractInstance[] memory contracts = byoc.getAllPublishedContracts(publisher);
        assertEq(contracts.length, 1);
        assertEq(contracts[0].contractId, "MockContract");

        string memory contractId = "MyContract";
        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
        IContractPublisher.CustomContractInstance[] memory contracts2 = byoc.getAllPublishedContracts(publisher);
        assertEq(contracts2.length, 2);
        assertEq(contracts2[0].contractId, "MockContract");
        assertEq(contracts2[1].contractId, "MyContract");
    }

    // Deprecated
    // function test_publish_emit_ContractPublished() public {
    //     string memory contractId = "MyContract";

    //     vm.prank(publisher);
    //     byoc.approveOperator(operator, true);

    //     IContractPublisher.CustomContractInstance memory expectedCustomContract = IContractPublisher
    //         .CustomContractInstance({
    //             contractId: contractId,
    //             publishTimestamp: 100,
    //             publishMetadataUri: publishMetadataUri,
    //             bytecodeHash: keccak256(type(MockCustomContract).creationCode),
    //             implementation: address(0)
    //         });

    //     vm.expectEmit(true, true, true, true);
    //     emit ContractPublished(operator, publisher, expectedCustomContract);

    //     vm.warp(100);
    //     vm.prank(operator);
    //     byoc.publishContract(
    //         publisher,
    //         publishMetadataUri,
    //         keccak256(type(MockCustomContract).creationCode),
    //         address(0),
    //         contractId
    //     );
    // }

    function test_unpublish_state() public {
        string memory contractId = "MyContract";

        vm.startPrank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            "publish URI 1",
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
        byoc.publishContract(
            publisher,
            contractId,
            "publish URI 2",
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
        byoc.publishContract(
            publisher,
            contractId,
            "publish URI 3",
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.stopPrank();

        IContractPublisher.CustomContractInstance[] memory allCustomContractsBefore = byoc.getPublishedContractVersions(
            publisher,
            contractId
        );
        assertEq(allCustomContractsBefore.length, 3);

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);

        IContractPublisher.CustomContractInstance memory customContract = byoc.getPublishedContract(
            publisher,
            contractId
        );

        assertEq(customContract.contractId, "");
        assertEq(customContract.publishMetadataUri, "");
        assertEq(customContract.bytecodeHash, bytes32(0));
        assertEq(customContract.implementation, address(0));

        IContractPublisher.CustomContractInstance[] memory allCustomContracts = byoc.getPublishedContractVersions(
            publisher,
            contractId
        );

        assertEq(allCustomContracts.length, 0);

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            "publish URI 4",
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        IContractPublisher.CustomContractInstance memory customContractRepublish = byoc.getPublishedContract(
            publisher,
            contractId
        );

        assertEq(customContractRepublish.contractId, contractId);
        assertEq(customContractRepublish.publishMetadataUri, "publish URI 4");

        IContractPublisher.CustomContractInstance[] memory allCustomContractsRepublish = byoc
            .getPublishedContractVersions(publisher, contractId);

        assertEq(allCustomContractsRepublish.length, 1);
    }

    // Deprecated
    // function test_unpublish_viaOperator() public {
    //     string memory contractId = "MyContract";

    //     vm.prank(publisher);
    //     byoc.publishContract(
    //         publisher,
    //         publishMetadataUri,
    //         keccak256(type(MockCustomContract).creationCode),
    //         address(0),
    //         contractId
    //     );

    //     vm.prank(publisher);
    //     byoc.approveOperator(operator, true);

    //     vm.prank(operator);
    //     byoc.unpublishContract(publisher, contractId);

    //     IContractPublisher.CustomContractInstance memory customContract = byoc.getPublishedContract(
    //         publisher,
    //         contractId
    //     );

    //     assertEq(customContract.contractId, "");
    //     assertEq(customContract.publishMetadataUri, "");
    //     assertEq(customContract.bytecodeHash, bytes32(0));
    //     assertEq(customContract.implementation, address(0));
    // }

    function test_unpublish_revert_unapprovedCaller() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.expectRevert("unapproved caller");

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);
    }

    function test_unpublish_revert_registryPaused() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            contractId,
            publishMetadataUri,
            compilerMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.prank(factoryAdmin);
        byoc.setPause(true);

        vm.expectRevert("registry paused");

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);
    }

    // Deprecated
    // function test_unpublish_emit_ContractUnpublished() public {
    //     string memory contractId = "MyContract";

    //     vm.prank(publisher);
    //     byoc.publishContract(
    //         publisher,
    //         publishMetadataUri,
    //         keccak256(type(MockCustomContract).creationCode),
    //         address(0),
    //         contractId
    //     );

    //     vm.prank(publisher);
    //     byoc.approveOperator(operator, true);

    //     vm.expectEmit(true, true, true, true);
    //     emit ContractUnpublished(operator, publisher, contractId);

    //     vm.prank(operator);
    //     byoc.unpublishContract(publisher, contractId);
    // }
}
