// ██████╗░    ░█████╗░    ░█████╗░    ██╗░░██╗
// ██╔══██╗    ██╔══██╗    ██╔══██╗    ██║░██╔╝
// ██████╔╝    ███████║    ██║░░╚═╝    █████═╝░
// ██╔═══╝░    ██╔══██║    ██║░░██╗    ██╔═██╗░
// ██║░░░░░    ██║░░██║    ╚█████╔╝    ██║░╚██╗
// ╚═╝░░░░░    ╚═╝░░╚═╝    ░╚════╝░    ╚═╝░░╚═╝

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ProtocolControl is AccessControl {

  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

  address public treasury;
  bool public protocolInitialized;
  bool public systemPaused;
  
  string public constant PACK = "PACK";
  string public constant MARKET = "MARKET";
  string public constant RNG = "RNG";
  

  mapping(bytes32 => address) public modules;
  mapping(string => bytes32) public moduleId;

  event ModuleAdded(string moduleName, bytes32 moduleId, address module);
  event ModuleUpdated(string moduleName, bytes32 moduleId, address module);
  event ModuleDeleted(string moduleName, bytes32 moduleId, address module);

  modifier onlyProtocolAdmin() {
    require(hasRole(PROTOCOL_ADMIN, msg.sender), "Only protocol admins can call this function.");
    _;
  }

  constructor(address _treasury) {
    treasury = _treasury;

    _setupRole(PROTOCOL_ADMIN, msg.sender);
    _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
  }

  /// @dev Iniializes the ERC 1155 module of the pack protocol.
  function initPackProtocol(
    address _pack,
    address _market,
    address _rng
  ) external onlyProtocolAdmin {
    require(!protocolInitialized, "The protocol has already been initialized.");

    addModule(PACK, _pack);
    addModule(MARKET, _market);
    addModule(RNG, _rng);
  }

  /// @dev Lets protocol admin pause the entire pack protocol system.
  function pausePackProtocol(bool _pause) onlyProtocolAdmin external {
    systemPaused = _pause;
  }

  /// @dev Lets protocol admin add a module to the pack protocol.
  function addModule(string memory _moduleName, address _moduleAddress) public onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] == address(0), "A module with this name already exists.");
    bytes32 id = keccak256(bytes(_moduleName));

    moduleId[_moduleName] = id;
    modules[id] = _moduleAddress;

    emit ModuleAdded(_moduleName, id, _moduleAddress);
  }

  /// @dev Lets protocol admin change address of a module of the pack protocol.
  function changeModuleAddress(string calldata _moduleName, address _newModuleAddress) external onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] != address(0), "The given module does not exist.");

    bytes32 id = keccak256(bytes(_moduleName));
    modules[id] = _newModuleAddress;

    emit ModuleUpdated(_moduleName, id, _newModuleAddress);
  }

  /// @dev Lets protocol admin delete a module of the pack protocol.
  function deleteModule(string calldata _moduleName) external onlyProtocolAdmin {
    require(modules[moduleId[_moduleName]] != address(0), "The given module does not exist.");

    bytes32 id = keccak256(bytes(_moduleName));

    delete modules[id];
    delete moduleId[_moduleName];

    emit ModuleDeleted(_moduleName, id, address(0));
  }

  /// @dev Returns a module of the pack protocol.
  function getModule(string memory _moduleName) public view returns (address) {
    return modules[moduleId[_moduleName]];
  }

  /// @notice Grants the `PROTOCOL_ADMIN` role to `_newAdmin`.
  function makeProtocolAdmin(address _newAdmin) external onlyProtocolAdmin {
    grantRole(PROTOCOL_ADMIN, _newAdmin);
  } 

  /// @notice Revokes the `PROTOCOL_ADMIN` role from `_revokeFrom`
  function removeProtocolAdmin(address _revokeFrom) external onlyProtocolAdmin {
    revokeRole(PROTOCOL_ADMIN, _revokeFrom);
  }

  /// @notice Lets protocol admin change the treaury address.
  function changeTreasury(address _newTreasury) external onlyProtocolAdmin {
    treasury = _newTreasury;
  }
}