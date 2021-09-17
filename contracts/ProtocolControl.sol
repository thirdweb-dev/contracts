// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolControl is AccessControl {
    
    /// @dev Admin role for protocol.
    bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");
    /// @dev Admin role for NFTLabs.
    bytes32 public constant NFTLABS = keccak256("NFTLABS");

    /// @dev Protocol status.
    bool public systemPaused;

    /// @dev NFTLabs protocol treasury
    address public nftlabsTreasury;

    /// @dev Pack protocol module names.
    enum ModuleType { Coin, NFT, Pack, Market, Other }

    /// @dev Module ID => Module address.
    mapping(bytes32 => address) public modules;
    /// @dev Module ID => Module type.
    mapping(bytes32 => ModuleType) public moduleType;
    /// @dev Module type => Num of modules of that type.
    mapping(uint => uint) public numOfModuleType;

    /// @dev Market fees
    uint256 public constant MAX_BPS = 10000; // 100%
    uint public marketFeeBps;

    /// @dev Events.
    event ProtocolInitialized(address pack, bytes32 packModuleId, address market, bytes32 marketModuleId, address coin, bytes32 coinModuleId, address nft, bytes32 nftModuleId);
    event ModuleInitialized(bytes32 moduleId, address module);
    event ModuleUpdated(bytes32 indexed moduleId, address indexed module, uint indexed moduleType);
    event FundsTransferred(address asset, address to, uint256 amount);
    event SystemPaused(bool isPaused);
    event MarketFeeBps(uint marketFeeBps);

    /// @dev Check whether the caller is a protocol admin
    modifier onlyProtocolAdmin() {
        require(hasRole(PROTOCOL_ADMIN, msg.sender), "Protocol: Only protocol admins can call this function.");
        _;
    }

    /// @dev Check whether the caller is an NFTLabs admin
    modifier onlyNftlabsAdmin() {
        require(hasRole(NFTLABS, msg.sender), "Protocol: Only NFTLabs admins can call this function.");
        _;
    }

    constructor(
        address _admin,
        address _nftlabs
    ) {

        nftlabsTreasury = _nftlabs;

        _setupRole(NFTLABS, _nftlabs);
        _setupRole(PROTOCOL_ADMIN, _admin);

        _setRoleAdmin(PROTOCOL_ADMIN, PROTOCOL_ADMIN);
        _setRoleAdmin(NFTLABS, NFTLABS);
    }

    /// @dev Iniializes all components of the protocol.
    function initializeProtocol(address _coin, address _nft, address _pack, address _market) external onlyProtocolAdmin {
        require(
            numOfModuleType[uint(ModuleType.Pack)] == 0 
            && numOfModuleType[uint(ModuleType.Market)] == 0
            && numOfModuleType[uint(ModuleType.NFT)] == 0
            && numOfModuleType[uint(ModuleType.Coin)] == 0,
            "Protocol Control: already initialized."
        );


        bytes32 packModuleId = addModule(_pack, uint(ModuleType.Pack));
        bytes32 marketModuleId = addModule(_market, uint(ModuleType.Market));
        bytes32 coinModuleId = addModule(_nft, uint(ModuleType.NFT));
        bytes32 nftModuleId = addModule(_coin, uint(ModuleType.Coin));

        emit ProtocolInitialized(_pack, packModuleId, _market, marketModuleId, _coin, coinModuleId, _nft, nftModuleId);
    }

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function addModule(address _newModuleAddress, uint _moduleType) public onlyProtocolAdmin returns (bytes32 moduleId)  {
        
        moduleId = keccak256(abi.encodePacked(numOfModuleType[_moduleType]));
        numOfModuleType[_moduleType] += 1;
        
        modules[moduleId] = _newModuleAddress;

        emit ModuleUpdated(moduleId, _newModuleAddress, _moduleType);
    }

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external onlyProtocolAdmin {
        modules[_moduleId] = _newModuleAddress;

        emit ModuleUpdated(_moduleId, _newModuleAddress, uint(moduleType[_moduleId]));
    }

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateMarketFeeBps(uint _newFeeBps) external onlyNftlabsAdmin {
        marketFeeBps = _newFeeBps;

        emit MarketFeeBps(_newFeeBps);
    }

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateNftlabsTreasury(address _newTreasury) external onlyNftlabsAdmin {
        nftlabsTreasury = _newTreasury;
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