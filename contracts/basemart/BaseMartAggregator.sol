// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../openzeppelin-presets/proxy/Clones.sol";
import "../openzeppelin-presets/utils/structs/EnumerableSet.sol";
import "../dynamic-contracts/extension/Ownable.sol";

library BaseMartStorage {
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION = keccak256("erc2771.context.storage");

    struct Data {
        EnumerableSet.AddressSet allMarts;
        mapping(address => address) martForCollection;
    }

    function baseMartStorage() internal pure returns (Data storage baseMartData) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            baseMartData.slot := position
        }
    }
}

contract BaseMartAggregator {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable implementation;

    constructor(address _baseMartImplementation) {
        implementation = _baseMartImplementation;
    }

    event MartCreated(address indexed mart, address indexed collection, address owner);

    function createMart(address _targetNFTCollection) external returns (address mart) {
        address owner = Ownable(_targetNFTCollection).owner();
        bytes32 salthash = keccak256(abi.encodePacked(owner, _targetNFTCollection));
        mart = Clones.cloneDeterministic(implementation, salthash);

        require(BaseMartStorage.baseMartStorage().allMarts.add(mart), "Already created.");
        BaseMartStorage.baseMartStorage().martForCollection[_targetNFTCollection] = mart;

        emit MartCreated(mart, _targetNFTCollection, owner);
    }

    function getAllMarts() external view returns (address[] memory) {
        return BaseMartStorage.baseMartStorage().allMarts.values();
    }

    function getMartForCollection(address _targetNFTCollection) external view returns (address mart) {
        return BaseMartStorage.baseMartStorage().martForCollection[_targetNFTCollection];
    }
}
