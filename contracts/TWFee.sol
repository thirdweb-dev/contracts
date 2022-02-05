// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Top-level contracts
import "./TWRegistry.sol";

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "./interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./lib/CurrencyTransferLib.sol";

contract TWFee is Multicall, ERC2771Context, AccessControlEnumerable {

    /// @dev The thirdweb registry of deployments.
    TWRegistry private immutable thirdwebRegistry;

    /// @dev The address of thirdweb's registry.
    address public thirdwebTreasury;

    /// @dev Only FEE_ROLE holders can set fee values.
    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint128 public constant MAX_BPS = 10_000;

    /// @dev The threshold for thirdweb fees. 1%
    uint128 public constant MAX_FEE_BPS = 100;

    /// @dev Mapping from pricing tier => FeeInfo
    mapping(uint256 => mapping(uint256 => FeeInfo)) public feeInfo;

    /// @dev Mapping from address => pricing tier for address.
    mapping(address => Tier) public tierForUser;

    /// @dev Mapping from tier => tier's pricing info.
    mapping(uint256 => TierInfo) private tierInfo;

    /**
     *  @dev Mapping from user => external party => whether the external party
     *       is approved to select a pricing tier for the user.
     */
    mapping(address => mapping(address => bool)) public isApproved;

    struct Tier {
        uint128 tier;
        uint128 validUntilTimestamp;
    }

    struct TierInfo {
        uint256 duration;
        mapping (address => uint256) priceForCurrency;
        mapping(address => bool) isCurrencyApproved;
    }

    struct FeeInfo {
        uint256 bps;
        address recipient;
    }

    /// @dev Events
    event TierForUser(address indexed user, uint256 indexed tier, address currencyForPayment, uint256 pricePaid, uint256 expirationTimestamp);
    event PricingTierInfo(uint256 indexed tier, uint256 _duration, address indexed currencyApproved, uint256 priceForCurrency);
    event FeeInfoForTier(uint256 indexed tier, uint256 indexed feeType, address recipient, uint256 bps);
    event NewTreasury(address oldTreasury, address newTreasury);

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    /// @dev Checks whether fee is under 1%
    modifier onlyValidFee(uint256 _feeBps) {
        require(_feeBps <= MAX_FEE_BPS, "fee too high.");
        _;
    }

    /// @dev Checks whether caller has FEE_ROLE.
    modifier onlyFeeAdmin() {
        require(hasRole(FEE_ROLE, _msgSender()), "not fee admin.");
        _;
    }

    constructor(address _trustedForwarder, address _thirdwebRegistry, address _thirdwebTreasury) ERC2771Context(_trustedForwarder) {
        thirdwebRegistry = TWRegistry(_thirdwebRegistry);
        thirdwebTreasury = _thirdwebTreasury;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FEE_ROLE, _msgSender());
    }

    /// @dev Returns the fee infor for a given module and fee type.
    function getFeeInfo(address _module, uint256 _feeType) external view returns (address recipient, uint256 bps) {
        address deployer = thirdwebRegistry.deployer(_module);
        Tier memory tierForDeployer = tierForUser[deployer];

        uint256 tierToUse = block.timestamp < tierForDeployer.validUntilTimestamp ? tierForDeployer.tier : 0;
        
        FeeInfo memory targetFeeInfo = feeInfo[tierToUse][_feeType];
        (recipient, bps) = (targetFeeInfo.recipient, targetFeeInfo.bps);
    }

    /// @dev Lets an approved caller select a subscription for `_for`.
    function selectSubscription(
        address _for,
        uint256 _tier,
        uint256 _priceToPay,
        address _currencyToUse
    )
        external 
        payable
    {
        address caller = _msgSender();
        require(
            _for == caller || isApproved[_for][caller] || hasRole(DEFAULT_ADMIN_ROLE, caller),
            "not approved to select tier."
        );

        uint256 durationForTier = tierInfo[_tier].duration;
        require(durationForTier != 0, "invalid tier.");

        bool isValidPaymentInfo = tierInfo[_tier].isCurrencyApproved[_currencyToUse] || tierInfo[_tier].priceForCurrency[_currencyToUse] == _priceToPay;
        require(isValidPaymentInfo, "invalid payment info.");

        Tier memory tierSelected = Tier({
            tier: uint128(_tier),
            validUntilTimestamp: uint128(block.timestamp + durationForTier)
        });

        tierForUser[_for] = tierSelected;

        CurrencyTransferLib.transferCurrency(_currencyToUse, _msgSender(), thirdwebTreasury, _priceToPay);

        emit TierForUser(_for, _tier, _currencyToUse, _priceToPay, tierSelected.validUntilTimestamp);
    }

    /// @dev Lets the caller renew a subscription for `_for`.
    function renewSubscription(
        address _for,
        address _currencyToUse,
        uint256 _priceToPay
    )
        external
        payable
    {
        Tier memory targetTier = tierForUser[_for];

        uint256 durationForTier = tierInfo[targetTier.tier].duration;
        require(durationForTier != 0, "invalid tier.");

        bool isValidPaymentInfo = tierInfo[targetTier.tier].isCurrencyApproved[_currencyToUse] || tierInfo[targetTier.tier].priceForCurrency[_currencyToUse] == _priceToPay;
        require(isValidPaymentInfo, "invalid payment info.");

        uint256 durationLeft = targetTier.validUntilTimestamp > block.timestamp ? targetTier.validUntilTimestamp - block.timestamp : 0;
        targetTier.validUntilTimestamp = uint128(block.timestamp + durationLeft + tierInfo[targetTier.tier].duration);

        tierForUser[_for] = targetTier;
        
        CurrencyTransferLib.transferCurrency(_currencyToUse, _msgSender(), thirdwebTreasury, _priceToPay);

        emit TierForUser(_for, targetTier.tier, _currencyToUse, _priceToPay, targetTier.validUntilTimestamp);
    }

    /// @dev For a tier, lets the admin set the (1) duration, (2) approve a currency for payment and (3) set price for that currency.
    function setPricingTierInfo(
        uint256 _tier,
        uint256 _duration,
        address _currencyToApprove,
        uint256 _priceForCurrency,
        bool _toApproveCurrency
    )
        external
        onlyModuleAdmin
    {
        tierInfo[_tier].duration = _duration;
        tierInfo[_tier].isCurrencyApproved[_currencyToApprove] = _toApproveCurrency;
        tierInfo[_tier].priceForCurrency[_currencyToApprove] = _toApproveCurrency ? _priceForCurrency : 0;

        emit PricingTierInfo(_tier, _duration, _currencyToApprove, _priceForCurrency);
    }

    /// @dev Lets the admin set fee bps and recipient for the given pricing tier and fee type.
    function setFeeInfoForTier(
        uint256 _tier,
        uint256 _feeBps,
        address _feeRecipient,
        uint256 _feeType
    ) 
        external
        onlyFeeAdmin
        onlyValidFee(_feeBps)
    {
        FeeInfo memory feeInfoToSet = FeeInfo({ bps: _feeBps, recipient: _feeRecipient });
        feeInfo[_tier][_feeType] = feeInfoToSet;

        emit FeeInfoForTier(_tier, _feeType, _feeRecipient, _feeBps);
    }

    /// @dev Lets module admin set thirdweb's treasury.
    function setTreasury(address _newTreasury) external onlyModuleAdmin {
        address oldTreasury = thirdwebTreasury;
        thirdwebTreasury = _newTreasury;

        emit NewTreasury(oldTreasury, _newTreasury);
    }

    //  =====   Getters   =====

    function isCurrencyApproved(uint256 _tier, address _currency) external view returns(bool) {
        return tierInfo[_tier].isCurrencyApproved[_currency];
    }

    function priceToPayForCurrency(uint256 _tier, address _currency) external view returns(uint256) {
        return tierInfo[_tier].priceForCurrency[_currency];
    }

    function tierDuration(uint256 _tier) external view returns(uint256) {
        return tierInfo[_tier].duration;
    }
   

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
