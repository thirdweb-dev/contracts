// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

//  ==========  Internal imports    ==========

import "./interfaces/IByocRegistry.sol";
import "./TWRegistry.sol";

contract ByocRegistry is IByocRegistry, AccessControlEnumerable {

    /// @dev The main thirdweb registry.
    TWRegistry private immutable registry;

    /// @dev Whether the registry is paused.
    bool public isPaused;
    
    /// @dev Mapping from publisher address => set of published contracts.
    mapping(address => CustomContractSet) private publishedContracts;

    /**
     *  @dev Mapping from publisher address => operator address => whether publisher has approved operator
     *       to publish / unpublish contracts on their behalf.
     */
    mapping(address => mapping(address => bool)) public isApprovedByPublisher;

    /// @dev Mapping from publisher address => publish metadata URI => contractId.
    mapping(address => mapping(string => uint256)) public contractId;

    modifier onlyApprovedOrPublisher(address _publisher) {
        require(
            msg.sender == _publisher || isApprovedByPublisher[_publisher][msg.sender],
            "unapproved caller"
        );

        _;
    }

    modifier onlyUnpausedOrAdmin() {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "registry paused");

        _;
    }

    constructor(address _twRegistry) {
        registry = TWRegistry(_twRegistry);
    }

    /// @notice Lets a publisher (caller) approve an operator to publish / unpublish contracts on their behalf.
    function approveOperator(address _operator, bool _toApprove) external {
        isApprovedByPublisher[msg.sender][_operator] = _toApprove;
        emit Approved(msg.sender, _operator, _toApprove);
    }

    /// @notice Returns all contracts published by a publisher.
    function getAllPublishedContracts(address _publisher) external view returns (CustomContract[] memory published) {
        uint256 total = publishedContracts[_publisher].id;
        uint256 net  = total - publishedContracts[_publisher].removed;

        published = new CustomContract[](net);

        uint256 publishedIndex;
        for(uint256 i = 0; i < total; i += 1) {
            if((publishedContracts[_publisher].contractAtId[i].bytecodeHash).length == 0) {
                continue;
            }

            published[publishedIndex] = publishedContracts[_publisher].contractAtId[i];
            publishedIndex += 1;
        }
    }

    /// @notice Returns a given contract published by a publisher.
    function getPublishedContract(address _publisher, uint256 _contractId) external view returns (CustomContract memory) {
        return publishedContracts[_publisher].contractAtId[_contractId];
    }

    /// @notice Let's an account publish a contract. The account must be approved by the publisher, or be the publisher.
    function publishContract(
        address _publisher,
        string memory _publishMetadataUri,
        bytes32 _bytecodeHash,
        address _implementation
    )
        external
        onlyApprovedOrPublisher(_publisher)
        onlyUnpausedOrAdmin
        returns (uint256 contractIdOfPublished)
    {
        contractIdOfPublished = publishedContracts[_publisher].id;
        publishedContracts[_publisher].id += 1;

        CustomContract memory publishedContract = CustomContract({
            contractId: contractIdOfPublished,
            publishMetadataUri: _publishMetadataUri,
            bytecodeHash: _bytecodeHash,
            implementation: _implementation
        });

        publishedContracts[_publisher].contractAtId[contractIdOfPublished] = publishedContract;
        contractId[_publisher][_publishMetadataUri] = contractIdOfPublished;

        emit ContractPublished(msg.sender, _publisher, contractIdOfPublished, publishedContract);
    }

    /// @notice Remove a contract from a publisher's set of published contracts.
    function unpublishContract(
        address _publisher,
        uint256 _contractId
    ) 
        external
        onlyApprovedOrPublisher(_publisher)
        onlyUnpausedOrAdmin
    {
        delete publishedContracts[_publisher].contractAtId[_contractId];
        publishedContracts[_publisher].removed += 1;

        emit ContractUnpublished(msg.sender, _publisher, _contractId);
    }

    /// @notice Deploys an instance of a published contract directly.
    function deployInstance(
        address _publisher,
        uint256 _contractId,
        bytes memory _contractBytecode,
        bytes memory _constructorArgs,
        bytes32 _salt,
        uint256 _value
    ) 
        external 
        onlyUnpausedOrAdmin
        returns (address deployedAddress)        
    {
        require(
            keccak256(_contractBytecode) == publishedContracts[_publisher].contractAtId[_contractId].bytecodeHash,
            "bytecode hash mismatch"
        );

        bytes memory contractBytecode = abi.encodePacked(_contractBytecode, _constructorArgs);
        deployedAddress = Create2.deploy(_value, _salt, contractBytecode);

        registry.add(_publisher, deployedAddress);

        emit ContractDeployed(msg.sender, _publisher, _contractId, deployedAddress);
    }

    /// @notice Deploys a clone pointing to an implementation of a published contract.
    function deployInstanceProxy(
        address _publisher,
        uint256 _contractId,
        bytes memory _initializeData,
        bytes32 _salt,
        uint256 _value
    )
        external
        onlyUnpausedOrAdmin
        returns (address deployedAddress)
    {
        address implementation = publishedContracts[_publisher].contractAtId[_contractId].implementation;
        require(implementation != address(0), "implementation DNE");

        deployedAddress = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encodePacked(msg.sender, _salt))
        );

        registry.add(_publisher, deployedAddress);

        if (_initializeData.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCallWithValue(deployedAddress, _initializeData, _value);
        }

        emit ContractDeployed(msg.sender, _publisher, _contractId, deployedAddress);
    }

    /// @dev Lets a contract admin pause the registry.
    function setPause(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "unapproved caller");
        isPaused = _pause;
        emit Paused(_pause);
    }
}