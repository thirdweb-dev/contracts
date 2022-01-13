// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Access
import "@openzeppelin/contracts/access/Ownable.sol";

// Utils
import { IThirdwebModule } from "./thirdweb-presets/IThirdwebModule.sol";

contract ThirdwebFees is Ownable {
    /// @dev Max bps in the thirdweb system
    uint128 public constant MAX_BPS = 10_000;

    /// @dev The threshold for thirdweb fees.
    uint128 public constant maxFeeBps = 3000;

    /// @dev The default royalty fee bps for thirdweb modules.
    uint256 public defaultRoyaltyFeeBps;

    /// @dev The default royalty fee recipient for thirdweb modules.
    address public defaultRoyaltyFeeRecipient;

    /// @dev The default sales fee bps for thirdweb modules.
    uint256 public defaultSalesFeeBps;

    /// @dev The default sales fee recipient for thirdweb modules.
    address public defaultSalesFeeRecipient;

    /// @dev Mapping from particular module instance => whether thirdweb takes no fees
    mapping(address => bool) public takeNoFee;

    /// @dev Mapping from module type => royalty fee bps
    mapping(bytes32 => mapping(FeeType => uint256)) public feeBpsByModuleType;

    /// @dev Mapping from particular module instance => royalty fee bps
    mapping(address => mapping(FeeType => uint256)) public feeBpsByModuleInstance;

    /// @dev Mapping from module type => royalty fee recipient
    mapping(bytes32 => mapping(FeeType => address)) public feeRecipientByModuleType;

    /// @dev Mapping from particular module instance => royalty fee recipient
    mapping(address => mapping(FeeType => address)) public feeRecipientByModuleInstance;

    /// @dev Emitted when fee is set for a module type
    event FeeForModuleType(uint256 feeBps, bytes32 moduleType, FeeType feeType);

    /// @dev Emitted when fee is set for a module instance
    event FeeForModuleInstance(uint256 feeBps, address moduleInstance, FeeType feeType);

    /// @dev Emitted when fee recipient is set for a module type
    event RecipientForModuleType(address recipient, bytes32 moduleType, FeeType feeType);

    /// @dev Emitted when fee recipient is set for a module instance
    event RecipientForModuleInstance(address recipient, address moduleInstance, FeeType feeType);

    enum FeeType { Sales, Royalty }

    modifier onlyValidFee(uint256 _feeBps) {
        require(_feeBps <= maxFeeBps, "fees too high");
        _;
    }

    constructor(
        uint256 _defaultRoyaltyFeeBps,
        address _defaultRoyaltyFeeRecipient,
        uint256 _defaultSalesFeeBps,
        address _defaultSalesFeeRecipient
    ) 
        Ownable()
    {
        defaultRoyaltyFeeBps = _defaultRoyaltyFeeBps;
        defaultRoyaltyFeeRecipient = _defaultRoyaltyFeeRecipient;
        defaultSalesFeeBps = _defaultSalesFeeBps;
        defaultSalesFeeRecipient = _defaultSalesFeeRecipient;
    }

    /// @dev Returns the royalty bps for a module address
    function getRoyaltyFeeBps(address _module) external view returns (uint256) {
        bytes32 moduleType = IThirdwebModule(_module).moduleType();

        if (takeNoFee[_module]) {
            return 0;
        } else if (feeBpsByModuleInstance[_module][FeeType.Royalty] > 0) {
            return feeBpsByModuleInstance[_module][FeeType.Royalty];
        } else if (feeBpsByModuleType[moduleType][FeeType.Royalty] > 0) {
            return feeBpsByModuleType[moduleType][FeeType.Royalty];
        } else {
            return defaultRoyaltyFeeBps;
        }
    }

    /// @dev Returns the royalty fee recipient for a module address
    function getRoyaltyFeeRecipient(address _module) external view returns (address) {
        bytes32 moduleType = IThirdwebModule(_module).moduleType();

        if (feeRecipientByModuleInstance[_module][FeeType.Royalty] != address(0)) {
            return feeRecipientByModuleInstance[_module][FeeType.Royalty];
        } else if (feeRecipientByModuleType[moduleType][FeeType.Royalty] != address(0)) {
            return feeRecipientByModuleType[moduleType][FeeType.Royalty];
        } else {
            return defaultRoyaltyFeeRecipient;
        }
    }

    /// @dev Returns the royalty bps for a module address
    function getSalesFeeBps(address _module) external view returns (uint256) {
        bytes32 moduleType = IThirdwebModule(_module).moduleType();

        if (takeNoFee[_module]) {
            return 0;
        } else if (feeBpsByModuleInstance[_module][FeeType.Sales] > 0) {
            return feeBpsByModuleInstance[_module][FeeType.Sales];
        } else if (feeBpsByModuleType[moduleType][FeeType.Sales] > 0) {
            return feeBpsByModuleType[moduleType][FeeType.Sales];
        } else {
            return defaultSalesFeeBps;
        }
    }

    /// @dev Returns the royalty fee recipient for a module address
    function getSalesFeeRecipient(address _module) external view returns (address) {
        bytes32 moduleType = IThirdwebModule(_module).moduleType();

        if (feeRecipientByModuleInstance[_module][FeeType.Sales] != address(0)) {
            return feeRecipientByModuleInstance[_module][FeeType.Sales];
        } else if (feeRecipientByModuleType[moduleType][FeeType.Sales] != address(0)) {
            return feeRecipientByModuleType[moduleType][FeeType.Sales];
        } else {
            return defaultSalesFeeRecipient;
        }
    }

    /// @dev Lets the owner set royalty fee bps for module type.
    function setFeeForModuleType(bytes32 _moduleType, uint256 _feeBps, FeeType _feeType) external onlyOwner onlyValidFee(_feeBps) {
        feeBpsByModuleType[_moduleType][_feeType] = _feeBps;
        emit FeeForModuleType(_feeBps, _moduleType, FeeType.Royalty);
    }

    /// @dev Lets the owner set royalty fee bps for a particular module instance.
    function setFeeForModuleInstance(address _moduleInstance, uint256 _feeBps, FeeType _feeType)
        external
        onlyOwner
        onlyValidFee(_feeBps)
    {
        feeBpsByModuleInstance[_moduleInstance][_feeType] = _feeBps;
        emit FeeForModuleInstance(_feeBps, _moduleInstance, FeeType.Royalty);
    }

    /// @dev Lets the owner set sales fee recipient for module type.
    function setRecipientForModuleType(bytes32 _moduleType, address _recipient, FeeType _feeType) external onlyOwner {
        feeRecipientByModuleType[_moduleType][_feeType] = _recipient;
        emit RecipientForModuleType(_recipient, _moduleType, _feeType);
    }

    /// @dev Lets the owner set sales fee recipient for a particular module instance.
    function setRecipientForModuleInstance(address _moduleInstance, address _recipient, FeeType _feeType) external onlyOwner {
        feeRecipientByModuleInstance[_moduleInstance][_feeType] = _recipient;
        emit RecipientForModuleInstance(_recipient, _moduleInstance, _feeType);
    }
}