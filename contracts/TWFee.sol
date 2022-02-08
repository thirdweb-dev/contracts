// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Top-level contracts
import "./TWRegistry.sol";
import "./TWPricing.sol";

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWFee is Multicall, ERC2771Context, AccessControlEnumerable {

    /// @dev The thirdweb registry of deployments.
    TWRegistry private immutable thirdwebRegistry;

    /// @dev The thirdweb store of pricing info per user.
    TWPricing private thirdwebPricing;

    /// @dev Only FEE_ROLE holders can set fee values.
    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE");

    /// @dev The threshold for thirdweb fees. 1%
    uint256 public constant MAX_FEE_BPS = 100;

    /// @dev Mapping from pricing tier => Fee Type => FeeInfo
    mapping(uint256 => mapping(uint256 => FeeInfo)) public feeInfo;

    struct FeeInfo {
        uint256 bps;
        address recipient;
    }

    /// @dev Events
    event FeeInfoForTier(uint256 indexed tier, uint256 indexed feeType, address recipient, uint256 bps);
    event NewThirdwebPricing(address oldThirdwebPricing, address newThirdwebPricing);

    constructor(address _trustedForwarder, address _thirdwebRegistry, address _thirdwebPricing) ERC2771Context(_trustedForwarder) {
        thirdwebRegistry = TWRegistry(_thirdwebRegistry);
        thirdwebPricing = TWPricing(_thirdwebPricing);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FEE_ROLE, _msgSender());
    }

    /// @dev Returns the fee infor for a given module and fee type.
    function getFeeInfo(address _module, uint256 _feeType) external view returns (address recipient, uint256 bps) {
        address deployer = thirdwebRegistry.deployer(_module);
        uint256 tier = thirdwebPricing.getTierForUser(deployer);
        
        FeeInfo memory targetFeeInfo = feeInfo[tier][_feeType];
        (recipient, bps) = (targetFeeInfo.recipient, targetFeeInfo.bps);
    }

    /// @dev Lets the admin set fee bps and recipient for the given pricing tier and fee type.
    function setFeeInfoForTier(
        uint256 _tier,
        uint256 _feeBps,
        address _feeRecipient,
        uint256 _feeType
    ) 
        external
    {
        require(_feeBps <= MAX_FEE_BPS, "fee too high.");
        require(hasRole(FEE_ROLE, _msgSender()), "not fee admin.");

        FeeInfo memory feeInfoToSet = FeeInfo({ bps: _feeBps, recipient: _feeRecipient });
        feeInfo[_tier][_feeType] = feeInfoToSet;

        emit FeeInfoForTier(_tier, _feeType, _feeRecipient, _feeBps);
    }
    
    /// @dev Lets a module admin set a new thirdweb-pricing info store address.
    function setThirdwebPricing(address _newThirdwebPricing) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");

        address oldThirdwebPricing = address(thirdwebPricing);
        thirdwebPricing = TWPricing(_newThirdwebPricing);

        emit NewThirdwebPricing(oldThirdwebPricing, _newThirdwebPricing);
    }

    //  =====   Getters   =====

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
