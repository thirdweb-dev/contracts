// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Access
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Utils
import "./interfaces/IThirdwebModule.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract TWFee is Multicall, ERC2771Context, AccessControlEnumerable {
    /// @dev Max bps in the thirdweb system.
    uint128 public constant MAX_BPS = 10_000;

    /// @dev The threshold for thirdweb fees. 1%
    uint128 public constant maxFeeBps = 100;

    /// @dev Mapping from module type => fee type => fee info
    mapping(bytes32 => mapping(FeeType => FeeInfo)) public feeInfoByModuleType;

    /// @dev Mapping from module instance => fee type => fee info
    mapping(address => mapping(FeeType => FeeInfo)) public feeInfoByModuleInstance;

    /// @dev Mapping from fee type => fee defaults
    mapping(FeeType => FeeInfo) public defaultFeeInfo;

    struct FeeInfo {
        uint256 bps;
        address recipient;
    }

    enum FeeType {
        Transaction,
        Royalty
    }

    event FeeInfoForModuleInstance(address indexed moduleInstance, FeeInfo feeInfo);
    event FeeInfoForModuleType(bytes32 indexed moduleType, FeeInfo feeInfo);
    event DefaultFeeInfo(FeeInfo feeInfo);
    
    modifier onlyValidFee(uint256 _feeBps) {
        require(_feeBps <= maxFeeBps, "fees too high");
        _;
    }

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    constructor(
        address _trustedForwarder,
        address _defaultRoyaltyFeeRecipient,
        address _defaultTransactionFeeRecipient,
        uint128 _defaultRoyaltyFeeBps,
        uint128 _defaultTransactionFeeBps
    )
        ERC2771Context(_trustedForwarder)
    {

        defaultFeeInfo[FeeType.Royalty] = FeeInfo({
            bps: _defaultRoyaltyFeeBps,
            recipient: _defaultRoyaltyFeeRecipient
        });

        defaultFeeInfo[FeeType.Transaction] = FeeInfo({
            bps: _defaultTransactionFeeBps,
            recipient: _defaultTransactionFeeRecipient
        });

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getFeeInfo(address _module, FeeType _feeType) external view returns (address recipient, uint256 bps) {
        bytes32 moduleType = IThirdwebModule(_module).moduleType();

        FeeInfo memory infoForModuleInstance = feeInfoByModuleInstance[_module][_feeType];
        FeeInfo memory infoForModuleType = feeInfoByModuleType[moduleType][_feeType];
        FeeInfo memory defaults = defaultFeeInfo[_feeType];

        // Get appropriate fee bps
        bps = infoForModuleInstance.bps;
        if(bps == 0) {
            bps = infoForModuleType.bps;
        }
        if(bps == 0) {
            bps = defaults.bps;
        }

        // Get appropriate fee recipient
        recipient = infoForModuleInstance.recipient;
        if(recipient == address(0)) {
            recipient = infoForModuleType.recipient;
        }
        if(recipient == address(0)) {
            recipient = defaults.recipient;
        }
    }

    /// @dev Lets the admin set fee bps and recipient for the given module type and fee type.
    function setFeeInfoForModuleType(
        bytes32 _moduleType,
        uint256 _feeBps,
        address _feeRecipient,
        FeeType _feeType
    ) external onlyModuleAdmin onlyValidFee(_feeBps) {
        FeeInfo memory feeInfo = FeeInfo({
            bps: _feeBps,
            recipient: _feeRecipient
        });

        feeInfoByModuleType[_moduleType][_feeType] = feeInfo;

        emit FeeInfoForModuleType(_moduleType, feeInfo);
    }

    /// @dev Lets the admin set fee bps and recipient for the given module instance and fee type.
    function setFeeInfoForModuleInstance(
        address _module,
        uint256 _feeBps,
        address _feeRecipient,
        FeeType _feeType
    ) external onlyModuleAdmin onlyValidFee(_feeBps) {
        FeeInfo memory feeInfo = FeeInfo({
            bps: _feeBps,
            recipient: _feeRecipient
        });

        feeInfoByModuleInstance[_module][_feeType] = feeInfo;

        emit FeeInfoForModuleInstance(_module, feeInfo);
    }

    /// @dev Lets the admin set fee bps and recipient for the given module instance and fee type.
    function setDefaultFeeInfo(
        uint256 _feeBps,
        address _feeRecipient,
        FeeType _feeType
    ) external onlyModuleAdmin onlyValidFee(_feeBps) {
        FeeInfo memory feeInfo = FeeInfo({
            bps: _feeBps,
            recipient: _feeRecipient
        });

        defaultFeeInfo[_feeType] = feeInfo;

        emit DefaultFeeInfo(feeInfo);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
