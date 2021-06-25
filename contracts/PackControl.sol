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
  string public constant PACK_RNG = "PACK_RNG";

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
    _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
  }

  /// @dev Iniializes the ERC 1155 module of the pack protocol.
  function initPackProtocol(address _packERC1155, address _packRNG) external onlyProtocolAdmin {
    require(
        modules[moduleId[PACK_ERC1155]] == address(0) && modules[moduleId[PACK_RNG]] == address(0),
        "The protocol has already been initialized."
    );

    bytes32 idERC1155 = keccak256(bytes(PACK_ERC1155));
    bytes32 idRNG = keccak256(bytes(PACK_RNG));

    moduleId[PACK_ERC1155] = idERC1155;
    moduleId[PACK_RNG] = idRNG;

    modules[idERC1155] = _packERC1155;
    modules[idRNG] = _packRNG;

    emit ModuleAdded(PACK_ERC1155, idERC1155, _packERC1155);
    emit ModuleAdded(PACK_RNG, idRNG, _packRNG);
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
  function getModule(string memory _moduleName) public view returns (address) {
    return modules[moduleId[_moduleName]];
  }

  /// @notice Pauses all activity in the ERC1155 part of the protocol.
  function pausePackERC1155() external onlyProtocolAdmin {
    ERC1155PresetMinterPauser(
      getModule(PACK_ERC1155)
    ).pause();
  }

  /// @notice Grants a role in the protocol's ERC1155 module.
  function grantRoleERC1155(bytes32 _role, address _receiver) external onlyProtocolAdmin {
    ERC1155PresetMinterPauser(
      getModule(PACK_ERC1155)
    ).grantRole(_role, _receiver);
  }

  /// @notice Revokes a role in the protocol's ERC1155 module.
  function revokeRoleERC1155(bytes32 _role, address _subject) external onlyProtocolAdmin {
    ERC1155PresetMinterPauser(
      getModule(PACK_ERC1155)
    ).revokeRole(_role, _subject);
  }

  /// @notice Grants the `PROTOCOL_ADMIN` role to `_newAdmin`.
  function makeProtocolAdmin(address _newAdmin) external onlyProtocolAdmin {
    grantRole(PROTOCOL_ADMIN, _newAdmin);
  } 
}