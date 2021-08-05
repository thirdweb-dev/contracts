// ░███████╗    ██████╗░    ░█████╗░    ░█████╗░    ██╗░░██╗
// ██╔██╔══╝    ██╔══██╗    ██╔══██╗    ██╔══██╗    ██║░██╔╝
// ╚██████╗░    ██████╔╝    ███████║    ██║░░╚═╝    █████═╝░
// ░╚═██╔██╗    ██╔═══╝░    ██╔══██║    ██║░░██╗    ██╔═██╗░
// ███████╔╝    ██║░░░░░    ██║░░██║    ╚█████╔╝    ██║░╚██╗
// ╚══════╝░    ╚═╝░░░░░    ╚═╝░░╚═╝    ░╚════╝░    ╚═╝░░╚═╝

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import { Pack } from "./Pack.sol";
import { Market } from "./Market.sol";

contract ProtocolControl is AccessControl {

  /// @dev Admin role for pack protocol.
  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

  /// @dev Protocol status.
  bool public systemPaused;
  
  /// @dev Pack protocol module names.
  bytes32 public constant PACK = keccak256("PACK");
  bytes32 public constant MARKET = keccak256("MARKET");

  /// @dev Module ID => Module address.
  mapping(bytes32 => address) public modules;

  /// @dev address => approved to accept protocol admin status.
  mapping(address => bool) public approvedForAdminRole;

  /// @dev Events.
  event NewAdmin(address _newAdmin);
  event AdminRemoved(address _removedAdmin);
  event ModuleInitialized(bytes32 moduleId, address module);
  event ModuleUpdated(bytes32 moduleId, address module);

  /// @dev Check whether the caller is a protocol admin
  modifier onlyProtocolAdmin() {
    require(hasRole(PROTOCOL_ADMIN, msg.sender), "Protocol: Only protocol admins can call this function.");
    _;
  }

  constructor() {
    _setupRole(PROTOCOL_ADMIN, msg.sender);
    _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
  }

  /// @dev Iniializes the ERC 1155 pack token of the protocol.
  function initializePack(
    string memory _packGlobalURI,

    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint _fees
  ) external onlyProtocolAdmin {
    require(modules[PACK] == address(0), "Protocol Control: Pack already been initialized.");

    // Deploy `Pack` ERC 1155 token.
    bytes memory packBytecode = abi.encodePacked(type(Pack).creationCode, abi.encode(
      address(this), _packGlobalURI, _vrfCoordinator, _linkToken, _keyHash, _fees
    ));
    address pack = Create2.deploy(0, PACK, packBytecode);

    // Update modules
    modules[PACK] = pack;

    emit ModuleInitialized(PACK, pack);
  }

  /// @dev Iniializes the market for packs and rewards.
  function initializeMarket() external onlyProtocolAdmin {
    require(modules[MARKET] == address(0), "Protocol Control: Pack already been initialized.");

    bytes memory marketBytecode = abi.encodePacked(type(Market).creationCode, abi.encode(address(this)));
    address market = Create2.deploy(0, MARKET, marketBytecode);

    // Update modules
    modules[MARKET] = market;

    emit ModuleInitialized(MARKET, market);
  }

  /// @dev Lets a protocol admin pause the entire protocol.
  function pauseProtocol(bool _pause) external onlyProtocolAdmin {
    systemPaused = _pause;
  }

  /// @dev Lets a protocol admin change the address of a module of the protocol.
  function updateModule(bytes32 _moduleId, address _newModuleAddress) external onlyProtocolAdmin {

    modules[_moduleId] = _newModuleAddress;

    emit ModuleUpdated(_moduleId, _newModuleAddress);
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

  /// @dev Lets a protocol admin transfer the accrued protocol fees.
  function transferProtocolFunds(address _asset, address _to, uint _amount) external onlyProtocolAdmin {
    require(IERC20(_asset).transfer(_to, _amount), "Protocol Control: failed to transfer protocol funds.");
  }
}