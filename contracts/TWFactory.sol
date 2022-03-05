// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./TWRegistry.sol";
import "./interfaces/IThirdwebContract.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract TWFactory is Multicall, ERC2771Context, AccessControlEnumerable {
    /// @dev Only FACTORY_ROLE holders can approve/unapprove implementations for proxies to point to.
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    TWRegistry public immutable registry;

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address proxy, address indexed deployer);
    event ImplementationAdded(address implementation, bytes32 indexed contractType, uint256 version);
    event ImplementationApproved(address implementation, bool isApproved);

    /// @dev mapping of implementation address to deployment approval
    mapping(address => bool) public approval;

    /// @dev mapping of implementation address to implementation added version
    mapping(bytes32 => uint256) public currentVersion;

    /// @dev mapping of contract type to module version to implementation address
    mapping(bytes32 => mapping(uint256 => address)) public implementation;

    /// @dev mapping of proxy address to deployer address
    mapping(address => address) public deployer;

    constructor(address _trustedForwarder, address _registry) ERC2771Context(_trustedForwarder) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FACTORY_ROLE, _msgSender());

        registry = TWRegistry(_registry);
    }

    /// @dev Deploys a proxy that points to the latest version of the given module type.
    function deployProxy(bytes32 _type, bytes memory _data) external returns (address) {
        bytes32 salt = bytes32(registry.count(_msgSender()));
        return deployProxyDeterministic(_type, _data, salt);
    }

    /**
     *  @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
     *       Proxy points to the latest version of the given module type.
     */
    function deployProxyDeterministic(
        bytes32 _type,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address) {
        address _implementation = implementation[_type][currentVersion[_type]];
        return deployProxyByImplementation(_implementation, _data, _salt);
    }

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) public returns (address deployedProxy) {
        require(approval[_implementation], "implementation not approved");

        bytes32 salthash = keccak256(abi.encodePacked(_msgSender(), _salt));
        deployedProxy = Clones.cloneDeterministic(_implementation, salthash);

        deployer[deployedProxy] = _msgSender();

        emit ProxyDeployed(_implementation, deployedProxy, _msgSender());

        registry.add(_msgSender(), deployedProxy);

        if (_data.length > 0) {
            // slither-disable-next-line unused-return
            Address.functionCall(deployedProxy, _data);
        }
    }

    /// @dev Lets a contract admin set the address of a module type x version.
    function addImplementation(address _implementation) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        IThirdwebContract module = IThirdwebContract(_implementation);
        bytes32 ctype = module.contractType();
        uint8 version = module.contractVersion();
        require(ctype.length > 0 && version > 0, "invalid module");

        currentVersion[ctype] += 1;
        require(currentVersion[ctype] == version, "wrong module version");

        implementation[ctype][version] = _implementation;
        approval[_implementation] = true;

        emit ImplementationAdded(_implementation, ctype, version);
    }

    /// @dev Lets a contract admin approve a specific contract for deployment.
    function approveImplementation(address _implementation, bool _toApprove) external {
        require(hasRole(FACTORY_ROLE, _msgSender()), "not admin.");

        approval[_implementation] = _toApprove;

        emit ImplementationApproved(_implementation, _toApprove);
    }

    /// @dev Returns the implementation given a module type and version.
    function getImplementation(bytes32 _type, uint256 _version) external view returns (address) {
        return implementation[_type][_version];
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
