// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
//  ==========  Internal imports    ==========

import "./interfaces/IByocRegistry.sol";
import "./TWRegistry.sol";

contract ByocRegistry is IByocRegistry {

    TWRegistry private immutable registry;
    
    mapping(address => CustomContractSet) private publishedContracts;

    constructor(address _twRegistry) {
        registry = TWRegistry(_twRegistry);
    }

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

    function publishContract(address _publisher, string memory _publishMetadataHash, bytes memory _creationCodeHash, address _implementation) external returns (uint256 contractId) {
        
        // TODO: add require statements

        contractId = publishedContracts[_publisher].id;
        publishedContracts[_publisher].id += 1;

        publishedContracts[_publisher].contractAtId[contractId] = CustomContract({
            publishMetadataHash: _publishMetadataHash,
            creationCodeHash: _creationCodeHash,
            implementation: _implementation
        });

        // TODO: emit event.
    }

    function unpublishContract(address _publisher, uint256 _contractId) external {
        // TODO: add require statements

        delete publishedContracts[_publisher].contractAtId[_contractId];
        publishedContracts[_publisher].removed += 1;

        // TODO: emit event.
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
        // TODO: other require statments
        require(
            keccak256(_creationCode) == keccak256(publishedContracts[_publisher].contractAtId[_contractId].creationCodeHash),
            "Creation code mismatch"
        );

        bytes memory contractBytecode = abi.encodePacked(_creationCode, _data);
        deployedAddress = Create2.deploy(_value, _salt, contractBytecode);

        registry.add(_publisher, deployedAddress);

        // TODO: emit event
    }

    function deployInstanceProxy(
        address _publisher,
        uint256 _contractId,
        bytes memory _data,
        bytes32 _salt
    )
        external
        returns (address deployedAddress)
    {
        // TODO: add require statements

        address implementation = publishedContracts[_publisher].contractAtId[_contractId].implementation;

        deployedAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        registry.add(_publisher, deployedAddress);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedAddress, _data);
        }

        // TODO: emit events
    }
}