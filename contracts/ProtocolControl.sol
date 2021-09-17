// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolControl is AccessControl {
    /// @dev Admin role for pack protocol.
    bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

    /// @dev Protocol status.
    bool public systemPaused;

    /// @dev Pack protocol module names.
    bytes32 public constant COIN = keccak256("COIN");
    bytes32 public constant NFT = keccak256("NFT");
    bytes32 public constant PACK = keccak256("PACK");
    bytes32 public constant MARKET = keccak256("MARKET");

    /// @dev Module ID => Module address.
    mapping(bytes32 => address) public modules;

    /// @dev Events.
    event ProtocolInitialized(address pack, address market, address coin, address nft);
    event ModuleInitialized(bytes32 moduleId, address module);
    event ModuleUpdated(bytes32 moduleId, address module);
    event FundsTransferred(address asset, address to, uint256 amount);
    event SystemPaused(bool isPaused);

    /// @dev Check whether the caller is a protocol admin
    modifier onlyProtocolAdmin() {
        require(hasRole(PROTOCOL_ADMIN, msg.sender), "Protocol: Only protocol admins can call this function.");
        _;
    }

    constructor(address _admin) {
        _setupRole(PROTOCOL_ADMIN, _admin);
        _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
    }

    /// @dev Iniializes the ERC 1155 pack token of the protocol.
    function initializeProtocol(address _coin, address _nft, address _pack, address _market) external onlyProtocolAdmin {
        require(
            modules[PACK] == address(0) && modules[MARKET] == address(0) && modules[COIN] == address(0) && modules[NFT] == address(0), 
            "Protocol Control: already initialized."
        );

        // Update modules
        modules[COIN] = _coin;
        modules[NFT] = _nft;
        modules[PACK] = _pack;
        modules[MARKET] = _market;

        emit ProtocolInitialized(_pack, _market, _coin, _nft);
    }

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external onlyProtocolAdmin {
        modules[_moduleId] = _newModuleAddress;

        emit ModuleUpdated(_moduleId, _newModuleAddress);
    }

    /// @dev Lets a protocol admin pause the protocol.
    function pausePackProtocol(bool _toPause) external onlyProtocolAdmin {
        systemPaused = _toPause;
        emit SystemPaused(_toPause);
    }

    /// @dev Lets a protocol admin transfer the accrued protocol fees.
    function transferProtocolFunds(
        address _asset,
        address _to,
        uint256 _amount
    ) external onlyProtocolAdmin {
        require(IERC20(_asset).transfer(_to, _amount), "Protocol Control: failed to transfer protocol funds.");

        emit FundsTransferred(_asset, _to, _amount);
    }
}