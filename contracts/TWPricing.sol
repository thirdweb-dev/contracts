// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Top-level contracts
import "./TWFee.sol";

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./lib/CurrencyTransferLib.sol";

contract TWPricing is Multicall, ERC2771Context, AccessControlEnumerable {
    /// @dev The thirdweb store of fee info.
    TWFee private immutable thirdwebFee;

    /// @dev The address of thirdweb's treasury.
    address public thirdwebTreasury;

    /// @dev Mapping from tier => tier's pricing info.
    mapping(uint256 => TierInfo) private tierInfo;

    /**
     *  @dev Mapping from user => external party => whether the external party
     *       is approved to select a pricing tier for the user.
     */
    mapping(address => mapping(address => bool)) public isApproved;

    struct TierInfo {
        uint256 duration;
        mapping(address => uint256) priceForCurrency;
        mapping(address => bool) isCurrencyApproved;
    }

    /// @dev Events
    event TierForUser(
        address indexed user,
        uint256 indexed tier,
        address currencyForPayment,
        uint256 pricePaid,
        uint256 expirationTimestamp
    );
    event PricingTierInfo(
        uint256 indexed tier,
        address indexed currency,
        bool isCurrencyApproved,
        uint256 _duration,
        uint256 priceForCurrency
    );

    event NewTreasury(address oldTreasury, address newTreasury);

    constructor(
        address _trustedForwarder,
        address _thirdwebTreasury,
        address _thirdwebFee
    ) ERC2771Context(_trustedForwarder) {
        thirdwebTreasury = _thirdwebTreasury;
        thirdwebFee = TWFee(_thirdwebFee);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Lets an approved caller select a subscription for `_for`.
    function selectSubscription(
        address _for,
        uint128 _tier,
        uint128 _cycles,
        uint256 _priceToPay,
        address _currencyToUse
    ) external payable {
        address caller = _msgSender();
        require(
            _for == caller || isApproved[_for][caller] || hasRole(DEFAULT_ADMIN_ROLE, caller),
            "not approved to select tier."
        );

        bool isValidPaymentInfo = _cycles != 0 &&
            (tierInfo[_tier].isCurrencyApproved[_currencyToUse] ||
                tierInfo[_tier].priceForCurrency[_currencyToUse] == _priceToPay);
        require(isValidPaymentInfo, "invalid payment info.");

        uint256 durationForTier = tierInfo[_tier].duration * _cycles;
        require(durationForTier != 0, "invalid tier.");

        (uint256 currentTier, uint256 secondsUntilExpiry) = thirdwebFee.getFeeTier(_for);
        if (currentTier == _tier) {
            durationForTier += secondsUntilExpiry;
        }

        thirdwebFee.setTierForUser(_for, _tier, uint128(block.timestamp + durationForTier));

        uint256 totalPrice = _priceToPay * _cycles;
        CurrencyTransferLib.transferCurrency(_currencyToUse, _msgSender(), thirdwebTreasury, totalPrice);

        emit TierForUser(_for, _tier, _currencyToUse, totalPrice, block.timestamp + durationForTier);
    }

    /// @dev For a tier, lets the admin set the (1) duration, (2) approve a currency for payment and (3) set price for that currency.
    function setPricingTierInfo(
        uint256 _tier,
        uint256 _duration,
        address _currencyToApprove,
        uint256 _priceForCurrency,
        bool _toApproveCurrency
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tierInfo[_tier].duration = _duration;
        tierInfo[_tier].isCurrencyApproved[_currencyToApprove] = _toApproveCurrency;
        tierInfo[_tier].priceForCurrency[_currencyToApprove] = _toApproveCurrency ? _priceForCurrency : 0;

        emit PricingTierInfo(_tier, _currencyToApprove, _toApproveCurrency, _duration, _priceForCurrency);
    }

    /// @dev Lets module admin set thirdweb's treasury.
    function setTreasury(address _newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldTreasury = thirdwebTreasury;
        thirdwebTreasury = _newTreasury;

        emit NewTreasury(oldTreasury, _newTreasury);
    }

    //  =====   Getters   =====

    function isCurrencyApproved(uint256 _tier, address _currency) external view returns (bool) {
        return tierInfo[_tier].isCurrencyApproved[_currency];
    }

    function priceToPayForCurrency(uint256 _tier, address _currency) external view returns (uint256) {
        return tierInfo[_tier].priceForCurrency[_currency];
    }

    function tierDuration(uint256 _tier) external view returns (uint256) {
        return tierInfo[_tier].duration;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
