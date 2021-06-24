// ██████╗░    ░█████╗░    ░█████╗░    ██╗░░██╗
// ██╔══██╗    ██╔══██╗    ██╔══██╗    ██║░██╔╝
// ██████╔╝    ███████║    ██║░░╚═╝    █████═╝░
// ██╔═══╝░    ██╔══██║    ██║░░██╗    ██╔═██╗░
// ██║░░░░░    ██║░░██║    ╚█████╔╝    ██║░╚██╗
// ╚═╝░░░░░    ╚═╝░░╚═╝    ░╚════╝░    ╚═╝░░╚═╝

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

contract PackControl is AccessControl {

  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");
  string public constant PACK_ERC1155 = "PACK_ERC1155";

  mapping(bytes32 => address) public modules;
  mapping(string => bytes32) public moduleId;

  event ModuleAdded(string moduleName, bytes32 moduleId, address module);
  event ModuleUpdated(string moduleName, bytes32 moduleId, address module);

  modifier onlyProtocolAdmin() {
    require(hasRole(PROTOCOL_ADMIN, msg.sender), "Only protocol admins can call this function.");
    _;
  }

  constructor() {
    _setupRole(PROTOCOL_ADMIN, msg.sender);
  }

  /// @dev Iniializes the ERC 1155 module of the pack protocol.
  function initPackERC1155(address _packERC1155) external onlyProtocolAdmin {
    require(modules[moduleId[PACK_ERC1155]] == address(0), "The ERC1155 module has already been initialized.");

    bytes32 id = keccak256(bytes(PACK_ERC1155));

    moduleId[PACK_ERC1155] = id;
    modules[id] = _packERC1155;

    emit ModuleAdded(PACK_ERC1155, id, _packERC1155);
  }

  /// @dev Lets protocol admin add a module to the pack protocol.
  function addModule(string calldata _moduleName, address _moduleAddress) public onlyProtocolAdmin {
    bytes32 id = keccak256(bytes(_moduleName));

    moduleId[_moduleName] = id;
    modules[id] = _moduleAddress;

    emit ModuleAdded(_moduleName, id, _moduleAddress);
  }

  /// @dev Lets protocol admin change address of a module of the pack protocol.
  function changeModuleAddress(string calldata _moduleName, address _newModuleAddress) external onlyProtocolAdmin {
    
    bytes32 id = keccak256(bytes(_moduleName));
    require(modules[id] != address(0), "The given module does not exist.");

    modules[id] = _newModuleAddress;

    emit ModuleUpdated(_moduleName, id, _newModuleAddress);
  }

  /// @dev Lets protocol admin delete a module of the pack protocol.
  function deleteModule(string calldata _moduleName) external onlyProtocolAdmin {

    bytes32 id = keccak256(bytes(_moduleName));
    require(modules[id] != address(0), "The given module does not exist.");

    delete modules[id];
    delete moduleId[_moduleName];

    emit ModuleUpdated(_moduleName, id, address(0));
  }

  /// @dev Returns a module of the pack protocol.
  function getModule(string calldata _moduleName) public view returns (address) {
    return modules[moduleId[_moduleName]];
  }

  /// @notice Pauses all activity in the ERC1155 part of the protocol.
  function pausePackERC1155(string calldata _moduleName) external onlyProtocolAdmin {
    ERC1155PresetMinterPauser(
      getModule(_moduleName)
    ).pause();
  }

  /// @notice Grants the `PROTOCOL_ADMIN` role to `_newAdmin`.
  function makeProtocolAdmin(address _newAdmin) external onlyProtocolAdmin {
    grantRole(PROTOCOL_ADMIN, _newAdmin);
  } 
}