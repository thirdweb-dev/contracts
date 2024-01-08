// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../../extension/plugin/ERC2771ContextConsumer.sol";
import "../../../extension/plugin/PermissionsEnumerableLogic.sol";

import "../../interface/ITWMultichainRegistry.sol";
import "./TWMultichainRegistryStorage.sol";

contract TWMultichainRegistryLogic is ITWMultichainRegistry, ERC2771ContextConsumer {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return bytes32("TWMultichainRegistry");
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(1);
    }

    /*///////////////////////////////////////////////////////////////
                            Core Functions
    //////////////////////////////////////////////////////////////*/

    // slither-disable-next-line similar-names
    function add(address _deployer, address _deployment, uint256 _chainId, string memory metadataUri) external {
        require(
            PermissionsEnumerableLogic(address(this)).hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(),
            "not operator or deployer."
        );

        TWMultichainRegistryStorage.Data storage data = TWMultichainRegistryStorage.multichainRegistryStorage();

        bool added = data.deployments[_deployer][_chainId].add(_deployment);
        require(added, "failed to add");

        data.chainIds.add(_chainId);

        if (bytes(metadataUri).length > 0) {
            data.addressToMetadataUri[_chainId][_deployment] = metadataUri;
        }

        emit Added(_deployer, _deployment, _chainId, metadataUri);
    }

    // slither-disable-next-line similar-names
    function remove(address _deployer, address _deployment, uint256 _chainId) external {
        require(
            PermissionsEnumerableLogic(address(this)).hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(),
            "not operator or deployer."
        );

        TWMultichainRegistryStorage.Data storage data = TWMultichainRegistryStorage.multichainRegistryStorage();

        bool removed = data.deployments[_deployer][_chainId].remove(_deployment);
        require(removed, "failed to remove");

        emit Deleted(_deployer, _deployment, _chainId);
    }

    function getAll(address _deployer) external view returns (Deployment[] memory allDeployments) {
        TWMultichainRegistryStorage.Data storage data = TWMultichainRegistryStorage.multichainRegistryStorage();
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
        TWMultichainRegistryStorage.Data storage data = TWMultichainRegistryStorage.multichainRegistryStorage();
        uint256 chainIdsLen = data.chainIds.length();

        for (uint256 i = 0; i < chainIdsLen; i += 1) {
            uint256 chainId = data.chainIds.at(i);

            deploymentCount += data.deployments[_deployer][chainId].length();
        }
    }

    function getMetadataUri(uint256 _chainId, address _deployment) external view returns (string memory metadataUri) {
        TWMultichainRegistryStorage.Data storage data = TWMultichainRegistryStorage.multichainRegistryStorage();
        metadataUri = data.addressToMetadataUri[_chainId][_deployment];
    }
}
