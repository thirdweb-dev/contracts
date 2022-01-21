// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract TWRegistry is Multicall, AccessControlEnumerable {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    struct Deployments {
        uint256 totalDeployments;
        uint256 totalDeleted;
        mapping(uint256 => address) moduleAddress;
        mapping(address => uint256) moduleIndex;
    }

    mapping(address => Deployments) public deployments;

    event ModuleDeployed(address indexed moduleAddress, address indexed deployer);
    event ModuleDeleted(address indexed moduleAddress, address indexed deployer);

    constructor(address _thirdwebFactory) AccessControlEnumerable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FACTORY_ROLE, _thirdwebFactory);
    }

    function addDeployment(
        address _moduleAddress,
        address _deployer
    ) external {
        require(hasRole(FACTORY_ROLE, msg.sender) || msg.sender == _deployer, "not factory");

        deployments[_deployer].totalDeployments += 1;
        uint256 idx = deployments[_deployer].totalDeployments;

        deployments[_deployer].moduleAddress[idx] = _moduleAddress;
        deployments[_deployer].moduleIndex[_moduleAddress] = idx;

        emit ModuleDeployed(_moduleAddress, _deployer);
    }

    function removeDeployment(address _moduleAddress) external {
        address deployer = _msgSender();
        uint256 moduleIdx = deployments[deployer].moduleIndex[_moduleAddress];
        
        require(moduleIdx != 0, "module does not exist");

        
        deployments[deployer].totalDeleted += 1;

        delete deployments[deployer].moduleAddress[moduleIdx];
        delete deployments[deployer].moduleIndex[_moduleAddress];

        emit ModuleDeleted(_moduleAddress, deployer);
    }

    function getAllModules(address _deployer)
        external
        view
        returns (address[] memory allModules)
    {
        uint256 totalDeployments = deployments[_deployer].totalDeployments;
        uint256 numOfModules = totalDeployments - deployments[_deployer].totalDeleted;
        allModules = new address[](numOfModules);

        for (uint256 i = 0; i < totalDeployments; i += 1) {
            if(deployments[_deployer].moduleAddress[i] != address(0)) {
                allModules[i] = deployments[_deployer].moduleAddress[i];
            }
        }
    }
}
