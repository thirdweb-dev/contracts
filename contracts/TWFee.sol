// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Top-level contracts
import "./TWRegistry.sol";

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWFee is Multicall, ERC2771Context, AccessControlEnumerable {

    /// @dev The thirdweb registry of deployments.
    TWRegistry private immutable thirdwebRegistry;

    /// @dev Only FEE_ROLE holders can set fee values.
    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE");

    /// @dev Only TIER_ADMIN_ROLE holders can assign tiers to users.
    bytes32 public constant TIER_ADMIN_ROLE = keccak256("FEE_ROLE");

    /// @dev The threshold for thirdweb fees. 1%
    uint256 public constant MAX_FEE_BPS = 100;

    /// @dev Mapping from address => pricing tier for address.
    mapping(address => Tier) public tierForUser;

    /// @dev Mapping from pricing tier => Fee Type => FeeInfo
    mapping(uint256 => mapping(uint256 => FeeInfo)) public feeInfo;

    struct Tier {
        uint128 tier;
        uint128 validUntilTimestamp;
    }

    struct FeeInfo {
        uint256 bps;
        address recipient;
    }

    /// @dev Events
    event TierForUser(address indexed user, uint256 tier, uint256 validUntilTimestamp);
    event FeeInfoForTier(uint256 indexed tier, uint256 indexed feeType, address recipient, uint256 bps);
    event NewThirdwebPricing(address oldThirdwebPricing, address newThirdwebPricing);

    constructor(
        address _trustedForwarder,
        address _thirdwebRegistry
    ) 
        ERC2771Context(_trustedForwarder)
    {
        thirdwebRegistry = TWRegistry(_thirdwebRegistry);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FEE_ROLE, _msgSender());
    }

    /// @dev Returns the fee tier for a user.
    function getFeeTier(address _user) public view returns (uint256 tier, uint256 secondsUntilExpiry) {
        Tier memory targetTier = tierForUser[_user];
        
        tier = block.timestamp < targetTier.validUntilTimestamp ? targetTier.tier : 0;
        secondsUntilExpiry = block.timestamp < targetTier.validUntilTimestamp ? targetTier.validUntilTimestamp - block.timestamp : 0;
    }

    /// @dev Returns the fee infor for a given module and fee type.
    function getFeeInfo(address _module, uint256 _feeType) external view returns (address recipient, uint256 bps) {
        address deployer = thirdwebRegistry.deployer(_module);
        (uint256 tier,) = getFeeTier(deployer);
        
        FeeInfo memory targetFeeInfo = feeInfo[tier][_feeType];
        (recipient, bps) = (targetFeeInfo.recipient, targetFeeInfo.bps);
    }

    /// @dev Lets a TIER_ADMIN_ROLE holder assign a tier to a user.
    function setTierForUser(address _user, uint128 _tier, uint128 _validUntilTimestamp) external {
        require(hasRole(TIER_ADMIN_ROLE, _msgSender()), "not tier admin.");

        tierForUser[_user] = Tier({
            tier: _tier,
            validUntilTimestamp: _validUntilTimestamp
        });

        emit TierForUser(_user, _tier, _validUntilTimestamp);
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

    //  =====   Getters   =====

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
