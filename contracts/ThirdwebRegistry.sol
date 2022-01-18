// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ThirdwebRegistry is AccessControlEnumerable {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    struct Deployments {
        uint256 totalDeployments;
        mapping(uint256 => address) moduleAddress;
    }

    mapping(bytes32 => mapping(address => Deployments)) public deployments;

    event ModuleDeployed(bytes32 indexed moduleType, address indexed moduleAddress, address indexed deployer);

    constructor(address _thirdwebFactory) AccessControlEnumerable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_ROLE, _thirdwebFactory);
    }

    function updateDeployments(
        bytes32 _moduleType,
        address _moduleAddress,
        address _deployer
    ) external {
        require(hasRole(FACTORY_ROLE, msg.sender) || msg.sender == _deployer, "not factory");

        uint256 id = deployments[_moduleType][_deployer].totalDeployments;
        deployments[_moduleType][_deployer].totalDeployments += 1;
        deployments[_moduleType][_deployer].moduleAddress[id] = _moduleAddress;

        emit ModuleDeployed(_moduleType, _moduleAddress, _deployer);
    }

    function getAllModulesOfType(bytes32 _moduleType, address _deployer)
        external
        view
        returns (address[] memory allModulesOfType)
    {
        uint256 numOfModulesOfType = deployments[_moduleType][_deployer].totalDeployments;
        allModulesOfType = new address[](numOfModulesOfType);

        for (uint256 i = 0; i < numOfModulesOfType; i += 1) {
            allModulesOfType[i] = deployments[_moduleType][_deployer].moduleAddress[i];
        }
    }
}
