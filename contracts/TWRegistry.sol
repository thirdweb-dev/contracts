// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWRegistry is Multicall, ERC2771Context, AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => EnumerableSet.AddressSet) private deployments;
    mapping(address => address) public deployer;

    event ModuleAdded(address indexed moduleAddress, address indexed deployer);
    event ModuleDeleted(address indexed moduleAddress, address indexed deployer);

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function addModule(address _moduleAddress, address _deployer) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "not operator.");
        deployments[_deployer].add(_moduleAddress);
        deployer[_moduleAddress] = _deployer;
        emit ModuleAdded(_moduleAddress, _deployer);
    }

    function removeModule(address _moduleAddress, address _deployer) external {
        require(hasRole(OPERATOR_ROLE, _msgSender()) || _deployer == _msgSender(), "not operator or deployer.");

        bool removed = deployments[_deployer].remove(_moduleAddress);
        require(removed, "failed to remove module.");
        delete deployer[_moduleAddress];

        emit ModuleDeleted(_moduleAddress, _deployer);
    }

    function getAllModules(address _deployer) external view returns (address[] memory) {
        return EnumerableSet.values(deployments[_deployer]);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
