// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Thirdweb contracts
import "./thirdweb-presets/TWAccessControl.sol";
import "./ThirdwebProxy.sol";
import "./ThirdwebRegistry.sol";
import "./thirdweb-presets/IThirdwebModule.sol";

// Utils
import "@openzeppelin/contracts/utils/Create2.sol";

contract ThirdwebFactory is TWAccessControl {
    address public thirdwebRegistry;

    /// @dev Emitted when a proxy is deployed.
    event ProxyDeployed(address indexed implementation, address indexed proxy, address indexed deployer);
    event NewModuleImplementation(bytes32 indexed moduleType, uint256 indexed version, address indexed implementation);
    event ImplementationApproved(address implementation, bool isApproved);

    mapping(address => bool) public approvedForDeployment;
    mapping(bytes32 => uint256) public currentModuleVersion;
    mapping(bytes32 => mapping(uint256 => address)) public modules;

    constructor() {
        __TWAccessControl_init(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        bytes memory registryBytecode = abi.encodePacked(
            type(ThirdwebRegistry).creationCode,
            abi.encode(address(this))
        );

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        thirdwebRegistry = Create2.deploy(0, salt, registryBytecode);
    }

    /// @dev Deploys a proxy that points to the latest version of the given module type.
    function deployProxy(bytes32 _moduleType, bytes memory _data) external {
        address implementation = modules[_moduleType][currentModuleVersion[_moduleType]];

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(implementation, _data)
        );
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        address deployedProxy = Create2.deploy(0, salt, proxyBytecode);

        ThirdwebRegistry(thirdwebRegistry).updateDeployments(_moduleType, deployedProxy, msg.sender);

        emit ProxyDeployed(implementation, deployedProxy, msg.sender);
    }

    /// @dev Deploys a proxy that points to the given implementation.
    function deployProxyToImplementation(address _implementation, bytes memory _data) external {
        require(approvedForDeployment[_implementation], "implementation not approved");

        bytes32 moduleType = IThirdwebModule(_implementation).moduleType();

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(_implementation, _data)
        );
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));

        address deployedProxy = Create2.deploy(0, salt, proxyBytecode);

        ThirdwebRegistry(thirdwebRegistry).updateDeployments(moduleType, deployedProxy, msg.sender);

        emit ProxyDeployed(_implementation, deployedProxy, msg.sender);
    }

    /**
     *  @dev Deploys a proxy at a deterministic address by taking in `salt` as a parameter.
     *       Proxy points to the latest version of the given module type.
     */
    function deployProxyDeterministic(
        bytes32 _moduleType,
        bytes memory _data,
        bytes32 _salt
    ) external {
        address implementation = modules[_moduleType][currentModuleVersion[_moduleType]];

        bytes memory proxyBytecode = abi.encodePacked(
            type(ThirdwebProxy).creationCode,
            abi.encode(implementation, _data)
        );

        address deployedProxy = Create2.deploy(0, _salt, proxyBytecode);

        ThirdwebRegistry(thirdwebRegistry).updateDeployments(_moduleType, deployedProxy, msg.sender);

        emit ProxyDeployed(implementation, deployedProxy, msg.sender);
    }

    /// @dev Lets a contract admin set the address of a module type x version.
    function addModuleImplementation(bytes32 _moduleType, address _implementation) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin.");
        require(IThirdwebModule(_implementation).moduleType() == _moduleType, "invalid module type.");

        currentModuleVersion[_moduleType] += 1;
        uint256 version = currentModuleVersion[_moduleType];

        modules[_moduleType][version] = _implementation;

        emit NewModuleImplementation(_moduleType, version, _implementation);
    }

    /// @dev Lets a contract admin approve a specific contract for deployment.
    function approveForDeployment(address _implementation, bool _toApprove) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin.");

        approvedForDeployment[_implementation] = _toApprove;

        emit ImplementationApproved(_implementation, _toApprove);
    }

    /// @dev Returns the implementation given a module type and version.
    function getImplementation(bytes32 _moduleType, uint256 _version) external view returns (address) {
        return modules[_moduleType][_version];
    }
}
