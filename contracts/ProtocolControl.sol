// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Registry
import { Registry } from "./Registry.sol";
import { Royalty } from "./Royalty.sol";

contract ProtocolControl is AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Protocol provider fees
    uint128 public constant MAX_BPS = 10000; // 100%

    /// @dev Module ID => Module address.
    mapping(bytes32 => address) public modules;

    /// @dev Module type => Num of modules of that type.
    mapping(uint256 => uint256) public numOfModuleType;

    /// @dev module address => royalty address
    mapping(address => address) private moduleRoyalty;

    address public registry;

    /// @dev deployer's treasury
    address public royaltyTreasury;
    address private _forwarder;

    /// @dev Contract level metadata.
    string private _contractURI;

    /// @dev Protocol status.
    bool public systemPaused;

    /// @dev Events.
    event ModuleUpdated(bytes32 indexed moduleId, address indexed module);
    event TreasuryUpdated(address _newTreasury);
    event ForwarderUpdated(address _newForwarder);
    event SystemPaused(bool isPaused);

    /// @dev Check whether the caller is a protocol admin
    modifier onlyProtocolAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Protocol: Only protocol admins can call this function.");
        _;
    }

    constructor(
        address _registry,
        address _admin,
        string memory _uri
    ) {
        // Set contract URI
        _contractURI = _uri;

        registry = _registry;
        royaltyTreasury = Registry(_registry).treasury();

        // Set access control roles
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @dev Initialize treasury payment royalty splitting pool
    function setRoyaltyTreasury(address payable _treasury) external onlyProtocolAdmin {
        require(_isRoyaltyTreasuryValid(_treasury), "fee is too low");
        royaltyTreasury = _treasury;
    }

    // @dev _treasury must be PaymentSplitter compatible interface.
    function setModuleRoyaltyTreasury(address moduleAddress, address payable _treasury) external onlyProtocolAdmin {
        require(_isRoyaltyTreasuryValid(_treasury), "fee is too low");
        moduleRoyalty[moduleAddress] = _treasury;
    }

    function _isRoyaltyTreasuryValid(address payable _treasury) private view returns (bool) {
        Royalty royalty = Royalty(_treasury);
        Registry _registry = Registry(registry);
        uint256 royaltyRegistryShares = royalty.shares(_registry.treasury());
        uint256 royaltyTotalShares = royalty.totalShares();
        uint256 registryCutBps = (royaltyRegistryShares * MAX_BPS) / royaltyTotalShares;

        // 10 bps (0.10%) tolerance in case of precision loss
        // making sure registry treasury gets at least the fee's worth of shares.
        uint256 feeBpsTolerance = 10;
        return registryCutBps >= (_registry.getFeeBps(address(this)) - feeBpsTolerance);
    }

    function getRoyaltyTreasury(address moduleAddress) external view returns (address) {
        address moduleRoyaltyTreasury = moduleRoyalty[moduleAddress];
        if (moduleRoyaltyTreasury == address(0)) {
            return royaltyTreasury;
        }
        return moduleRoyaltyTreasury;
    }

    /// @dev Lets a protocol admin add a module to the protocol.
    function addModule(address _newModuleAddress, uint256 _moduleType)
        external
        onlyProtocolAdmin
        returns (bytes32 moduleId)
    {
        // `moduleId` is collision resitant -- unique `_moduleType` and incrementing `numOfModuleType`
        moduleId = keccak256(abi.encodePacked(numOfModuleType[_moduleType], _moduleType));
        numOfModuleType[_moduleType] += 1;

        modules[moduleId] = _newModuleAddress;

        emit ModuleUpdated(moduleId, _newModuleAddress);
    }

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external onlyProtocolAdmin {
        require(modules[_moduleId] != address(0), "ProtocolControl: a module with this ID does not exist.");

        modules[_moduleId] = _newModuleAddress;

        emit ModuleUpdated(_moduleId, _newModuleAddress);
    }

    /// @dev Lets a protocol admin pause the protocol.
    function pauseProtocol(bool _toPause) external onlyProtocolAdmin {
        systemPaused = _toPause;
        emit SystemPaused(_toPause);
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    function setForwarder(address forwarder) external onlyProtocolAdmin {
        _forwarder = forwarder;
        emit ForwarderUpdated(forwarder);
    }

    /// @dev Returns the URI for the contract-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Returns all addresses for a module type
    function getAllModulesOfType(uint256 _moduleType) external view returns (address[] memory allModules) {
        uint256 numOfModules = numOfModuleType[_moduleType];
        allModules = new address[](numOfModules);

        for (uint256 i = 0; i < numOfModules; i += 1) {
            bytes32 moduleId = keccak256(abi.encodePacked(i, _moduleType));
            allModules[i] = modules[moduleId];
        }
    }

    function getForwarder() public view returns (address) {
        if (_forwarder == address(0)) {
            return Registry(registry).forwarder();
        }
        return _forwarder;
    }
}
