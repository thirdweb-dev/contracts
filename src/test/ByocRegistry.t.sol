// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import { ByocRegistry } from "contracts/ByocRegistry.sol";
import "contracts/interfaces/IByocRegistry.sol";
import "contracts/TWRegistry.sol";

// Test helpers
import { BaseTest } from "./utils/BaseTest.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract MockCustomContract {
    uint256 public num;

    constructor(uint256 _num) {
        num = _num;
    }
}

contract IByocRegistryData {
    /// @dev Emitted when the registry is paused.
    event Paused(bool isPaused);

    /// @dev Emitted when a publisher's approval of an operator is updated.
    event Approved(address indexed publisher, address indexed operator, bool isApproved);

    /// @dev Emitted when a contract is published.
    event ContractPublished(
        address indexed operator,
        address indexed publisher,
        IByocRegistry.CustomContractInstance publishedContract
    );

    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is added to the public list.
    event AddedContractToPublicList(address indexed publisher, string indexed contractId);

    /// @dev Emitted when a published contract is removed from the public list.
    event RemovedContractToPublicList(address indexed publisher, string indexed contractId);
}

contract ByocRegistryTest is BaseTest, IByocRegistryData {
    ByocRegistry internal byoc;
    TWRegistry internal twRegistry;

    address internal publisher;
    address internal operator;
    address internal deployerOfPublished;

    string internal publishMetadataUri = "ipfs://QmeXyz";

    function setUp() public override {
        super.setUp();

        byoc = ByocRegistry(byocRegistry);
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
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        IByocRegistry.CustomContractInstance memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, contractId);
        assertEq(customContract.publishMetadataUri, publishMetadataUri);
        assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
        assertEq(customContract.implementation, address(0));
    }

    function test_publish_viaOperator() public {
        
        string memory contractId = "MyContract";
        
        vm.prank(publisher);
        byoc.approveOperator(operator, true);
        
        vm.prank(operator);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        IByocRegistry.CustomContractInstance memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, contractId);
        assertEq(customContract.publishMetadataUri, publishMetadataUri);
        assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
        assertEq(customContract.implementation, address(0));
    }

    function test_publish_revert_unapprovedCaller() public {
        string memory contractId = "MyContract";

        vm.expectRevert("unapproved caller");

        vm.prank(operator);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
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
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );
    }

    function test_publish_emit_ContractPublished() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        IByocRegistry.CustomContractInstance memory expectedCustomContract = IByocRegistry.CustomContractInstance({
            contractId: contractId,
            publishTimestamp: 100,
            publishMetadataUri: publishMetadataUri,
            bytecodeHash: keccak256(type(MockCustomContract).creationCode),
            implementation: address(0)
        });

        vm.expectEmit(true, true, true, true);
        emit ContractPublished(operator, publisher, expectedCustomContract);

        vm.warp(100);
        vm.prank(operator);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );
    }

    function test_unpublish() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);

        IByocRegistry.CustomContractInstance memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, "");
        assertEq(customContract.publishMetadataUri, "");
        assertEq(customContract.bytecodeHash, bytes32(0));
        assertEq(customContract.implementation, address(0));
    }

    function test_unpublish_viaOperator() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);

        IByocRegistry.CustomContractInstance memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, "");
        assertEq(customContract.publishMetadataUri, "");
        assertEq(customContract.bytecodeHash, bytes32(0));
        assertEq(customContract.implementation, address(0));
    }

    function test_unpublish_revert_unapprovedCaller() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
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
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        vm.prank(factoryAdmin);
        byoc.setPause(true);

        vm.expectRevert("registry paused");

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);
    }

    function test_unpublish_emit_ContractUnpublished() public {
        string memory contractId = "MyContract";

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0),
            contractId
        );

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        vm.expectEmit(true, true, true, true);
        emit ContractUnpublished(operator, publisher, contractId);

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);
    }
}
