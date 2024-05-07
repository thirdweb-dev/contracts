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

contract TWRegistry is Multicall, ERC2771Context, AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev wallet address => [contract addresses]
    mapping(address => EnumerableSet.AddressSet) private deployments;

    event Added(address indexed deployer, address indexed deployment);
    event Deleted(address indexed deployer, address indexed deployment);

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // slither-disable-next-line similar-names
    function add(address _deployer, address _deployment) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(), "not operator or deployer.");

        bool added = deployments[_deployer].add(_deployment);
        require(added, "failed to add");

        emit Added(_deployer, _deployment);
    }

    // slither-disable-next-line similar-names
    function remove(address _deployer, address _deployment) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(), "not operator or deployer.");

        bool removed = deployments[_deployer].remove(_deployment);
        require(removed, "failed to remove");

        emit Deleted(_deployer, _deployment);
    }

    function getAll(address _deployer) external view returns (address[] memory) {
        return deployments[_deployer].values();
    }

    function count(address _deployer) external view returns (uint256) {
        return deployments[_deployer].length();
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context, Multicall) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
