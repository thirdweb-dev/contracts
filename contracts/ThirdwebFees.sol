// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Upgradeability
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// Access
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Utils
import { IThirdwebModule } from "./IThirdwebModule.sol";

contract ThirdwebFees is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    /// @dev Max bps in the thirdweb system
    uint128 constant public MAX_BPS = 10_000;

    /// @dev The threshold for thirdweb fees.
    uint128 constant public maxFeeBps = 3000;

    /// @dev The default fee bps for thirdweb modules.
    uint256 public defaultFeeBps;

    /// @dev The default fee recipient for thirdweb modules.
    address public defaultFeeRecipient;

    /// @dev Mapping from particular module instance => whether thirdweb takes no fees
    mapping(address => bool) public takeNoFee;

    /// @dev Mapping from module type => fee bps
    mapping(bytes32 => uint256) public feeBpsByModuleType;

    /// @dev Mapping from particular module instance => fee bps
    mapping(address => uint256) public feeBpsByModuleInstance;

    /// @dev Mapping from module type => fee recipient
    mapping(bytes32 => address) public feeRecipientByModuleType;

    /// @dev Mapping from particular module instance => fee recipient
    mapping(address => address) public feeRecipientByModuleInstance;

    /// @dev Emitted when fee is set for a module type
    event FeeForModuleType(uint256 feeBps, bytes32 moduleType);

    /// @dev Emitted when fee is set for a module instance
    event FeeForModuleInstance(uint256 feeBps, address moduleInstance);

    /// @dev Emitted when fee recipient is set for a module type
    event RecipientForModuleType(address recipient, bytes32 moduleType);

    /// @dev Emitted when fee recipient is set for a module instance
    event RecipientForModuleInstance(address recipient, address moduleInstance);

    modifier onlyValidFee(uint256 _feeBps) {
        require(_feeBps <= maxFeeBps, "fees too high");
        _;
    }

    /// @dev Returns the fee bps for a module address
    function getFeeBps(address _module) external view returns (uint256) {

        bytes32 moduleType = IThirdwebModule(_module).moduleType();
        
        if(takeNoFee[_module]) {
            return 0;
        
        } else if (feeBpsByModuleInstance[_module] > 0) {
            return feeBpsByModuleInstance[_module];
        
        } else if (feeBpsByModuleType[moduleType] > 0) {
            return feeBpsByModuleType[moduleType];
        
        } else {
            return defaultFeeBps;
        }
    }

    /// @dev Initializes contract state.
    function initialize(uint256 _defaultFeeBps, address _defaultFeeRecipient) external initializer {
        
        // Initialize inherited contracts.
        __Ownable_init();

        defaultFeeBps = _defaultFeeBps;
        defaultFeeRecipient = _defaultFeeRecipient;
    }

    /// @dev Lets the owner set fee bps for module type.
    function setFeeForModuleType(bytes32 _moduleType, uint256 _feeBps) external onlyOwner onlyValidFee(_feeBps) {
        feeBpsByModuleType[_moduleType] = _feeBps;
        emit FeeForModuleType(_feeBps, _moduleType);
    }

    /// @dev Lets the owner set fee bps for a particular module instance.
    function setFeeForModuleInstance(address _moduleInstance, uint256 _feeBps) external onlyOwner onlyValidFee(_feeBps) {
        feeBpsByModuleInstance[_moduleInstance] = _feeBps;
        emit FeeForModuleInstance(_feeBps, _moduleInstance);
    }

    /// @dev Lets the owner set fee recipient for module type.
    function setRecipientForModuleType(bytes32 _moduleType, address _recipient) external onlyOwner {
        feeRecipientByModuleType[_moduleType] = _recipient;
        emit RecipientForModuleType(_recipient, _moduleType);
    }

    /// @dev Lets the owner set fee recipient for a particular module instance.
    function setRecipientForModuleInstance(address _moduleInstance, address _recipient) external onlyOwner {
        feeRecipientByModuleInstance[_moduleInstance] = _recipient;
        emit RecipientForModuleInstance(_recipient, _moduleInstance);
    }

    /// @dev Runs on every upgrade.
    // TODO: define restrictions on upgrades.
    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}