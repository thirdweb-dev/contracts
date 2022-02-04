// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TWProxy.sol";
import "./TWRegistry.sol";
import "./interfaces/IThirdwebModule.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "@openzeppelin/contracts/utils/Multicall.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWFactory is Multicall, ERC2771Context, AccessControlEnumerable {
    /// @dev Only FACTORY_ROLE holders can approve/unapprove implementations for proxies to point to.
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    TWRegistry public immutable registry;

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event moduleImplementationAdded(bytes32 indexed moduleType, uint256 version, address implementation);
    event ImplementationApproved(address implementation, bool isApproved);

    mapping(address => bool) public implementationApproval;
    mapping(bytes32 => uint256) public currentModuleVersion;
    mapping(bytes32 => mapping(uint256 => address)) public modules;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FACTORY_ROLE, _msgSender());

        registry = new TWRegistry(_trustedForwarder);
    }

    /// @dev Deploys a proxy that points to the latest version of the given module type.
    function deployProxy(bytes32 _moduleType, bytes memory _data) external {
        bytes32 salt = keccak256(abi.encodePacked(_moduleType, block.number));
        deployProxyDeterministic(_moduleType, _data, salt);
    }

    /**
     *  @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
     *       Proxy points to the latest version of the given module type.
     */
    function deployProxyDeterministic(
        bytes32 _moduleType,
        bytes memory _data,
        bytes32 _salt
    ) public {
        address implementation = modules[_moduleType][currentModuleVersion[_moduleType]];
        deployProxyByImplementation(implementation, _data, _salt);
    }

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) public {
        require(implementationApproval[_implementation], "implementation not approved");

        bytes memory proxyBytecode = abi.encodePacked(type(TWProxy).creationCode, abi.encode(_implementation, _data));

        address deployedProxy = Create2.deploy(0, _salt, proxyBytecode);

        registry.addModule(deployedProxy, _msgSender());

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());
    }

    /// @dev Lets a contract admin set the address of a module type x version.
    function addModuleImplementation(bytes32 _moduleType, address _implementation) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");
        require(IThirdwebModule(_implementation).moduleType() == _moduleType, "invalid module type.");

        currentModuleVersion[_moduleType] += 1;
        uint256 version = currentModuleVersion[_moduleType];

        modules[_moduleType][version] = _implementation;
        implementationApproval[_implementation] = true;

        emit moduleImplementationAdded(_moduleType, version, _implementation);
    }

    /// @dev Lets a contract admin approve a specific contract for deployment.
    function approveImplementation(address _implementation, bool _toApprove) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        implementationApproval[_implementation] = _toApprove;

        emit ImplementationApproved(_implementation, _toApprove);
    }

    /// @dev Returns the implementation given a module type and version.
    function getImplementation(bytes32 _moduleType, uint256 _version) external view returns (address) {
        return modules[_moduleType][_version];
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
