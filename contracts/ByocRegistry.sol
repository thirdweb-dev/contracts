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

    TWRegistry private immutable registry;

    bool public isPaused;
    
    mapping(address => CustomContractSet) private publishedContracts;
    mapping(address => mapping(address => bool)) public isApproved;

    constructor(address _twRegistry) {
        registry = TWRegistry(_twRegistry);
    }

    /// @notice Returns all contracts published by a publisher.
    function getPublishedContracts(address _publisher) external view returns (CustomContract[] memory published) {
        uint256 total = publishedContracts[_publisher].id;
        uint256 net  = total - publishedContracts[_publisher].removed;

        published = new CustomContract[](net);

        uint256 publishedIndex;
        for(uint256 i = 0; i < total; i += 1) {
            if((publishedContracts[_publisher].contractAtId[i].creationCodeHash).length == 0) {
                continue;
            }

            published[publishedIndex] = publishedContracts[_publisher].contractAtId[i];
            publishedIndex += 1;
        }
    }

    /// @notice Add a contract to a publisher's set of published contracts.
    function publishContract(
        string memory _publishMetadataHash,
        bytes memory _creationCodeHash,
        address _implementation
    )
        external 
        returns (uint256 contractId)
    {

        // creationCode => bytecode
        // data => constructorArgs
        // Additional method to associate implementation => publishContract.

        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "registry paused");

        contractId = publishedContracts[msg.sender].id;
        publishedContracts[msg.sender].id += 1;

        CustomContract memory publishedContract = CustomContract({
            contractId: contractId,
            publishMetadataHash: _publishMetadataHash,
            creationCodeHash: _creationCodeHash,
            implementation: _implementation
        });

        publishedContracts[msg.sender].contractAtId[contractId] = publishedContract;

        emit ContractPublished(msg.sender, contractId, publishedContract);
    }

    /// @notice Remove a contract from a publisher's set of published contracts.
    function unpublishContract(address _publisher, uint256 _contractId) external {
        require(
            msg.sender == _publisher || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "unapproved caller"
        );

        delete publishedContracts[_publisher].contractAtId[_contractId];
        publishedContracts[_publisher].removed += 1;

        emit ContractUnpublished(msg.sender, _publisher, _contractId);
    }

    /// @notice Deploys an instance of a published contract directly.
    function deployInstance(
        address _publisher,
        uint256 _contractId,
        bytes memory _creationCode,
        bytes memory _data,
        bytes32 _salt,
        uint256 _value
    ) 
        external 
        returns (address deployedAddress)        
    {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "registry paused");
        require(
            keccak256(_creationCode) == publishedContracts[_publisher].contractAtId[_contractId].creationCodeHash,
            "Creation code mismatch"
        );

        bytes memory contractBytecode = abi.encodePacked(_creationCode, _data);
        deployedAddress = Create2.deploy(_value, _salt, contractBytecode);

        registry.add(_publisher, deployedAddress);

        emit ContractDeployed(msg.sender, _publisher, _contractId, deployedAddress);
    }

    /// @notice Deploys a clone pointing to an implementation of a published contract.
    function deployInstanceProxy(
        address _publisher,
        uint256 _contractId,
        bytes memory _data,
        bytes32 _salt
    )
        external
        returns (address deployedAddress)
    {
        require(!isPaused || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "registry paused");

        address implementation = publishedContracts[_publisher].contractAtId[_contractId].implementation;
        require(implementation != address(0), "implementation DNE");

        deployedAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        registry.add(_publisher, deployedAddress);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedAddress, _data);
        }

        emit ContractDeployed(msg.sender, _publisher, _contractId, deployedAddress);
    }

    function setPause(bool _pause) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "unapproved caller");
        isPaused = _pause;
        emit Paused(_pause);
    }
}