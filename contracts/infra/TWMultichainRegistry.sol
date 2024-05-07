// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../extension/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./interface/ITWMultichainRegistry.sol";

contract TWMultichainRegistry is ITWMultichainRegistry, Multicall, ERC2771Context, AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev wallet address => [contract addresses]
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet)) private deployments;
    /// @dev contract address deployed => imported metadata uri
    mapping(uint256 => mapping(address => string)) private addressToMetadataUri;

    EnumerableSet.UintSet private chainIds;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // slither-disable-next-line similar-names
    function add(address _deployer, address _deployment, uint256 _chainId, string memory metadataUri) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(), "not operator or deployer.");

        bool added = deployments[_deployer][_chainId].add(_deployment);
        require(added, "failed to add");

        chainIds.add(_chainId);

        if (bytes(metadataUri).length > 0) {
            addressToMetadataUri[_chainId][_deployment] = metadataUri;
        }

        emit Added(_deployer, _deployment, _chainId, metadataUri);
    }

    // slither-disable-next-line similar-names
    function remove(address _deployer, address _deployment, uint256 _chainId) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(), "not operator or deployer.");

        bool removed = deployments[_deployer][_chainId].remove(_deployment);
        require(removed, "failed to remove");

        emit Deleted(_deployer, _deployment, _chainId);
    }

    function getAll(address _deployer) external view returns (Deployment[] memory allDeployments) {
        uint256 totalDeployments;
        uint256 chainIdsLen = chainIds.length();

        for (uint256 i = 0; i < chainIdsLen; i += 1) {
            uint256 chainId = chainIds.at(i);

            totalDeployments += deployments[_deployer][chainId].length();
        }

        allDeployments = new Deployment[](totalDeployments);
        uint256 idx;

        for (uint256 j = 0; j < chainIdsLen; j += 1) {
            uint256 chainId = chainIds.at(j);

            uint256 len = deployments[_deployer][chainId].length();
            address[] memory deploymentAddrs = deployments[_deployer][chainId].values();

            for (uint256 k = 0; k < len; k += 1) {
                allDeployments[idx] = Deployment({
                    deploymentAddress: deploymentAddrs[k],
                    chainId: chainId,
                    metadataURI: addressToMetadataUri[chainId][deploymentAddrs[k]]
                });
                idx += 1;
            }
        }
    }

    function count(address _deployer) external view returns (uint256 deploymentCount) {
        uint256 chainIdsLen = chainIds.length();

        for (uint256 i = 0; i < chainIdsLen; i += 1) {
            uint256 chainId = chainIds.at(i);

            deploymentCount += deployments[_deployer][chainId].length();
        }
    }

    function getMetadataUri(uint256 _chainId, address _deployment) external view returns (string memory metadataUri) {
        metadataUri = addressToMetadataUri[_chainId][_deployment];
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context, Multicall) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
