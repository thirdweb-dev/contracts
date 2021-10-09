// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IControlDeployer {
    event DeployedControl(address indexed registry, address indexed deployer, address indexed control);

    function deployControl(address registry, uint256 nonce, address deployer, string memory uri) external returns (address);
}
