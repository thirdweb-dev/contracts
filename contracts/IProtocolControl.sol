// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/IAccessControl.sol";

// Tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProtocolControl is IAccessControl {
    /// @dev Admin role for protocol.
    function PROTOCOL_ADMIN() external view returns (bytes32);
    /// @dev Admin role for NFTLabs.
    function NFTLABS() external view returns (bytes32);

    /// @dev Protocol status.
    function systemPaused() external view returns (bool);

    /// @dev NFTLabs protocol treasury
    function nftlabsTreasury() external view returns (address);

    /// @dev Pack protocol module names.
    enum ModuleType {
        Coin,
        NFTCollection,
        NFT,
        DynamicNFT,
        AccessNFT,
        Pack,
        Market,
        Other
    }

    /// @dev Module ID => Module address.
    function modules(bytes32) external view returns (address);
    /// @dev Module ID => Module type.
    function moduleType(bytes32) external view returns (ModuleType);
    /// @dev Module type => Num of modules of that type.
    function numOfModuleType(uint256) external view returns (uint256);

    /// @dev Market fees
    function MAX_BPS() external view returns (uint256);
    function marketFeeBps() external view returns (uint256);

    /// @dev Contract level metadata.
    function _contractURI() external view returns (string memory);

    /// @dev Events.
    event ModuleUpdated(bytes32 indexed moduleId, address indexed module, uint256 indexed moduleType);
    event FundsTransferred(address asset, address to, uint256 amount);
    event SystemPaused(bool isPaused);
    event MarketFeeBps(uint256 marketFeeBps);
    event NFTLabsTreasury(address _nftlabsTreasury);

    /// @dev Lets a protocol admin add a module to the protocol.
    function addModule(address _newModuleAddress, uint8 _moduleType) external returns (bytes32 moduleId);
    

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external;

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateMarketFeeBps(uint128 _newFeeBps) external;

    /// @dev Lets a nftlabs admin change the market fee basis points.
    function updateNftlabsTreasury(address _newTreasury) external;

    /// @dev Lets a protocol admin pause the protocol.
    function pauseProtocol(bool _toPause) external;

    /// @dev Lets a protocol admin transfer this contract's funds.
    function transferProtocolFunds(address _asset,address _to,uint256 _amount) external;

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external;

    /// @dev Returns the URI for the contract-level metadata of the contract.
    function contractURI() external view returns (string memory);

    /// @dev Returns all addresses for a module type
    function getAllModulesOfType(uint256 _moduleType) external view returns (address[] memory allModules);
}
