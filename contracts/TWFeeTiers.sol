// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "./interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWFeeTiers is Multicall, ERC2771Context, AccessControlEnumerable {
    /// @dev Only FEE_ROLE holders can set fee values.
    bytes32 public constant FEE_ROLE = keccak256("FEE_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint128 public constant MAX_BPS = 10_000;

    /// @dev The threshold for thirdweb fees. 1%
    uint128 public constant MAX_FEE_BPS = 100;

    uint256 public totalPricingTiers;

    struct Tier {
        uint256 tier;
        uint128 startTimestamp;
        uint128 durationInSeconds;
        uint256 price;
        address currency;
    }

    /// @dev Mapping from address => pricing tier for address.
    mapping(address => Tier) public pricingTier;

    mapping(address => mapping(address => bool)) public isApproved;

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    function selectPricingTier(address _for, uint256 _tier) external payable {
        require(_tier < totalPricingTiers, "non-existent tier.");
        address caller = _msgSender();
        require(
            _for == caller || isApproved[_for][caller] || hasRole(DEFAULT_ADMIN_ROLE, caller),
            "not approved to select tier."
        );
    }
   

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
