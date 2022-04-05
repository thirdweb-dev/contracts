// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Target contracts
import "contracts/ByocRegistry.sol";
import "contracts/interfaces/IByocRegistry.sol";
import "contracts/TWRegistry.sol";

// Test helpers
import "./utils/BaseTest.sol";
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
    event ContractPublished(address indexed operator, address indexed publisher, uint256 indexed contractId, IByocRegistry.CustomContract publishedContract);
    /// @dev Emitted when a contract is unpublished.
    event ContractUnpublished(address indexed operator, address indexed publisher, uint256 indexed contractId);
    /// @dev Emitted when a contract is deployed.
    event ContractDeployed(address indexed deployer, address indexed publisher, uint256 indexed contractId, address deployedContract);
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

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        IByocRegistry.CustomContract memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, contractId);
        assertEq(customContract.publishMetadataUri, publishMetadataUri);
        assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
        assertEq(customContract.implementation, address(0));
    }

    function test_publish_viaOperator() public {

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        vm.prank(operator);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        IByocRegistry.CustomContract memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, contractId);
        assertEq(customContract.publishMetadataUri, publishMetadataUri);
        assertEq(customContract.bytecodeHash, keccak256(type(MockCustomContract).creationCode));
        assertEq(customContract.implementation, address(0));
    }

    function test_publish_revert_unapprovedCaller() public {

        vm.expectRevert("unapproved caller");

        vm.prank(operator);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
    }

    function test_publish_revert_registryPaused() public {

        vm.prank(factoryAdmin);
        byoc.setPause(true);

        vm.expectRevert("registry paused");

        vm.prank(publisher);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
    }

    function test_publish_emit_ContractPublished() public {

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        IByocRegistry.CustomContract memory expectedCustomContract = IByocRegistry.CustomContract({
            contractId: 0,
            publishMetadataUri: publishMetadataUri,
            bytecodeHash: keccak256(type(MockCustomContract).creationCode),
            implementation: address(0)
        });

        vm.expectEmit(true, true, true, true);
        emit ContractPublished(operator, publisher, expectedCustomContract.contractId, expectedCustomContract);

        vm.prank(operator);
        byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );
    }

    function test_unpublish() public {

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);

        IByocRegistry.CustomContract memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, 0);
        assertEq(customContract.publishMetadataUri, "");
        assertEq(customContract.bytecodeHash, bytes32(0));
        assertEq(customContract.implementation, address(0));
    }

    function test_unpublish_viaOperator() public {

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);

        IByocRegistry.CustomContract memory customContract = byoc.getPublishedContract(publisher, contractId);

        assertEq(customContract.contractId, 0);
        assertEq(customContract.publishMetadataUri, "");
        assertEq(customContract.bytecodeHash, bytes32(0));
        assertEq(customContract.implementation, address(0));
    }

    function test_unpublish_revert_unapprovedCaller() public {

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.expectRevert("unapproved caller");

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);
    }

    function test_unpublish_revert_registryPaused() public {

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.prank(factoryAdmin);
        byoc.setPause(true);

        vm.expectRevert("registry paused");

        vm.prank(publisher);
        byoc.unpublishContract(publisher, contractId);
    }

    function test_unpublish_emit_ContractUnpublished() public {

        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        vm.prank(publisher);
        byoc.approveOperator(operator, true);

        vm.expectEmit(true, true, true, true);
        emit ContractUnpublished(operator, publisher, contractId);

        vm.prank(operator);
        byoc.unpublishContract(publisher, contractId);
    }

    function test_deployInstance() public {
        vm.prank(publisher);
        uint256 contractId = byoc.publishContract(
            publisher,
            publishMetadataUri,
            keccak256(type(MockCustomContract).creationCode),
            address(0)
        );

        uint256 num = 10;
        address predictedAddr = Create2.computeAddress(
            bytes32("hello"),
            keccak256(abi.encodePacked(type(MockCustomContract).creationCode, abi.encode(num))),
            address(byoc)
        );

        vm.prank(deployerOfPublished);
        address deployedAddress = byoc.deployInstance(
            publisher, 
            contractId, 
            type(MockCustomContract).creationCode, 
            abi.encode(num), 
            bytes32("hello"),
            0
        );

        assertEq(deployedAddress, predictedAddr);
        assertEq(MockCustomContract(deployedAddress).num(), num);
    }
}