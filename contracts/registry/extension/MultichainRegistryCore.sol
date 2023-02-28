// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../interfaces/ITWMultichainRegistry.sol";

import "../../extension/interface/IPermissions.sol";
import "../../extension/interface/IERC2771Context.sol";

import "../../openzeppelin-presets/utils/EnumerableSet.sol";

library MultichainRegistryStorage {
    bytes32 public constant MULTICHAIN_REGISTRY_STORAGE_POSITION = keccak256("multichain.registry.storage");

    struct Data {
        /// @dev wallet address => [contract addresses]
        mapping(address => mapping(uint256 => EnumerableSet.AddressSet)) deployments;
        /// @dev contract address deployed => imported metadata uri
        mapping(uint256 => mapping(address => string)) addressToMetadataUri;
        EnumerableSet.UintSet chainIds;
    }

    function multichainRegistryStorage() internal pure returns (Data storage multichainRegistryData) {
        bytes32 position = MULTICHAIN_REGISTRY_STORAGE_POSITION;
        assembly {
            multichainRegistryData.slot := position
        }
    }
}

contract MultichainRegistryCore is ITWMultichainRegistry {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return bytes32("MultichainRegistry");
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(1);
    }

    /*///////////////////////////////////////////////////////////////
                            Core Functions
    //////////////////////////////////////////////////////////////*/

    // slither-disable-next-line similar-names
    function add(
        address _deployer,
        address _deployment,
        uint256 _chainId,
        string memory metadataUri
    ) external {
        require(
            IPermissions(address(this)).hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(),
            "Multichain Registry: not operator or deployer."
        );

        MultichainRegistryStorage.Data storage data = MultichainRegistryStorage.multichainRegistryStorage();

        bool added = data.deployments[_deployer][_chainId].add(_deployment);
        require(added, "Multichain Registry: contract already added.");

        data.chainIds.add(_chainId);

        if (bytes(metadataUri).length > 0) {
            data.addressToMetadataUri[_chainId][_deployment] = metadataUri;
        }

        emit Added(_deployer, _deployment, _chainId, metadataUri);
    }

    // slither-disable-next-line similar-names
    function remove(
        address _deployer,
        address _deployment,
        uint256 _chainId
    ) external {
        require(
            IPermissions(address(this)).hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(),
            "Multichain Registry: not operator or deployer."
        );

        MultichainRegistryStorage.Data storage data = MultichainRegistryStorage.multichainRegistryStorage();

        bool removed = data.deployments[_deployer][_chainId].remove(_deployment);
        require(removed, "Multichain Registry: contract already removed.");

        emit Deleted(_deployer, _deployment, _chainId);
    }

    function getAll(address _deployer) external view returns (Deployment[] memory allDeployments) {
        MultichainRegistryStorage.Data storage data = MultichainRegistryStorage.multichainRegistryStorage();
        uint256 totalDeployments;
        uint256 chainIdsLen = data.chainIds.length();

        for (uint256 i = 0; i < chainIdsLen; i += 1) {
            uint256 chainId = data.chainIds.at(i);

            totalDeployments += data.deployments[_deployer][chainId].length();
        }

        allDeployments = new Deployment[](totalDeployments);
        uint256 idx;

        for (uint256 j = 0; j < chainIdsLen; j += 1) {
            uint256 chainId = data.chainIds.at(j);

            uint256 len = data.deployments[_deployer][chainId].length();
            address[] memory deploymentAddrs = data.deployments[_deployer][chainId].values();

            for (uint256 k = 0; k < len; k += 1) {
                allDeployments[idx] = Deployment({
                    deploymentAddress: deploymentAddrs[k],
                    chainId: chainId,
                    metadataURI: data.addressToMetadataUri[chainId][deploymentAddrs[k]]
                });
                idx += 1;
            }
        }
    }

    function count(address _deployer) external view returns (uint256 deploymentCount) {
        MultichainRegistryStorage.Data storage data = MultichainRegistryStorage.multichainRegistryStorage();
        uint256 chainIdsLen = data.chainIds.length();

        for (uint256 i = 0; i < chainIdsLen; i += 1) {
            uint256 chainId = data.chainIds.at(i);

            deploymentCount += data.deployments[_deployer][chainId].length();
        }
    }

    function getMetadataUri(uint256 _chainId, address _deployment) external view returns (string memory metadataUri) {
        MultichainRegistryStorage.Data storage data = MultichainRegistryStorage.multichainRegistryStorage();
        metadataUri = data.addressToMetadataUri[_chainId][_deployment];
    }

    /*///////////////////////////////////////////////////////////////
                            Internal overrides
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view returns (address sender) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view returns (bytes calldata) {
        if (IERC2771Context(address(this)).isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}
