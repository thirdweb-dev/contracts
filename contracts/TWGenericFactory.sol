// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./interfaces/IThirdwebContract.sol";
import "./extension/interface/IContractFactory.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract TWGenericFactory is Multicall, ERC2771Context, AccessControlEnumerable, IContractFactory {
    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);

    /// @dev mapping of proxy address to deployer address
    mapping(address => address) public deployer;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) public override returns (address deployedProxy) {
        bytes32 salthash = keccak256(abi.encodePacked(_msgSender(), _salt));
        deployedProxy = Clones.cloneDeterministic(_implementation, salthash);

        deployer[deployedProxy] = _msgSender();

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedProxy, _data);
        }
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
