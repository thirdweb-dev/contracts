// ██████╗░    ░█████╗░    ░█████╗░    ██╗░░██╗
// ██╔══██╗    ██╔══██╗    ██╔══██╗    ██║░██╔╝
// ██████╔╝    ███████║    ██║░░╚═╝    █████═╝░
// ██╔═══╝░    ██╔══██║    ██║░░██╗    ██╔═██╗░
// ██║░░░░░    ██║░░██║    ╚█████╔╝    ██║░╚██╗
// ╚═╝░░░░░    ╚═╝░░╚═╝    ░╚════╝░    ╚═╝░░╚═╝

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract ProtocolControl is AccessControl {

  /// @dev Admin role for pack protocol.
  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

  /// @dev The pack protocol treasury address.
  address public treasury;

  /// @dev Protocol status.
  bool public protocolInitialized;
  bool public systemPaused;
  
  /// @dev Pack protocol module names.
  string public constant PACK = "PACK";
  string public constant MARKET = "MARKET";
  string public constant RNG = "RNG";
  
  /// @dev Module name => Module ID.
  mapping(string => bytes32) public moduleId;

  /// @dev Module ID => Module address.
  mapping(bytes32 => address) public modules;

  /// @dev address => approved to accept protocol admin status.
  mapping(address => bool) public approvedForAdminRole;

  /// @dev Events.
  event ModuleAdded(string moduleName, bytes32 moduleId, address module);
  event ModuleUpdated(string moduleName, bytes32 moduleId, address module);
  event ModuleDeleted(string moduleName, bytes32 moduleId, address module);
  event NewAdmin(address _newAdmin);
  event AdminRemoved(address _removedAdmin);

  /// @dev Check whether the caller is a protocol admin
  modifier onlyProtocolAdmin() {
    require(hasRole(PROTOCOL_ADMIN, msg.sender), "Protocol Control: Only protocol admins can call this function.");
    _;
  }

  constructor(address _treasury) {
    treasury = _treasury;

    _setupRole(PROTOCOL_ADMIN, msg.sender);
    _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
  }

  /// @dev Iniializes the pack protocol.
  function initPackProtocol(
    address _pack,
    address _market,
    address _rng
  ) external onlyProtocolAdmin {
    require(!protocolInitialized, "Protocol Control: The protocol has already been initialized.");

    addModule(PACK, _pack);
    addModule(MARKET, _market);
    addModule(RNG, _rng);
  }

  /// @dev Lets protocol admin pause the entire pack protocol system.
  function pausePackProtocol(bool _pause) external onlyProtocolAdmin {
    systemPaused = _pause;
  }

  /// @dev Lets protocol admin add a module to the pack protocol.
  function addModule(string memory _moduleName, address _moduleAddress) public onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] == address(0), "Protocol Control: A module with this name already exists.");
    bytes32 id = keccak256(bytes(_moduleName));

    moduleId[_moduleName] = id;
    modules[id] = _moduleAddress;

    emit ModuleAdded(_moduleName, id, _moduleAddress);
  }

  /// @dev Lets protocol admin change address of a module of the pack protocol.
  function changeModuleAddress(string calldata _moduleName, address _newModuleAddress) external onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] != address(0), "Protocol Control: The given module does not exist.");

    bytes32 id = keccak256(bytes(_moduleName));
    modules[id] = _newModuleAddress;

    emit ModuleUpdated(_moduleName, id, _newModuleAddress);
  }

  /// @dev Lets protocol admin delete a module of the pack protocol.
  function deleteModule(string calldata _moduleName) external onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] != address(0), "Protocol Control: The given module does not exist.");

    bytes32 id = keccak256(bytes(_moduleName));

    delete modules[id];
    delete moduleId[_moduleName];

    emit ModuleDeleted(_moduleName, id, address(0));
  }

  /// @dev Returns the address of a module of the pack protocol.
  function getModule(string memory _moduleName) public view returns (address) {
    return modules[moduleId[_moduleName]];
  }

  /// @dev Grants the `PROTOCOL_ADMIN` role to `_newAdmin`.
  function makeProtocolAdmin(address _newAdmin) external onlyProtocolAdmin {
    approvedForAdminRole[_newAdmin] = true;
  } 

  /// @dev Lets an address approved for the protocol admin role accept the role.
  function acceptProtocolAdminRole() external {
    require(approvedForAdminRole[msg.sender], "Protocol Control: not approved to accept admin role.");
    _setupRole(PROTOCOL_ADMIN, msg.sender);

    emit NewAdmin(msg.sender);
  }

  /// @dev Revokes the `PROTOCOL_ADMIN` role from `_revokeFrom`
  function removeProtocolAdmin(address _revokeFrom) external onlyProtocolAdmin {
    revokeRole(PROTOCOL_ADMIN, _revokeFrom);
    approvedForAdminRole[_revokeFrom] = false;

    emit AdminRemoved(_revokeFrom);
  }

  /// @dev Lets protocol admin change the treaury address.
  function changeTreasury(address _newTreasury) external onlyProtocolAdmin {
    treasury = _newTreasury;
  }
}