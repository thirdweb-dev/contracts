// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

// Base
import "../../external-deps/openzeppelin/finance/PaymentSplitterUpgradeable.sol";
import "../../infra/interface/IThirdwebContract.sol";

// Meta-tx
import "../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";

// Access
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "../../lib/FeeType.sol";

contract Split is
    IThirdwebContract,
    Initializable,
    MulticallUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    PaymentSplitterUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Split");
    uint128 private constant VERSION = 1;

    /// @dev Max bps in the thirdweb system
    uint128 private constant MAX_BPS = 10_000;

    /// @dev Contract level metadata.
    string public contractURI;

    constructor() initializer {}

    /// @dev Performs the job of the constructor.
    /// @dev shares_ are scaled by 10,000 to prevent precision loss when including fees
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address[] memory _payees,
        uint256[] memory _shares
    ) external initializer {
        // Initialize inherited contracts: most base -> most derived
        __ERC2771Context_init(_trustedForwarders);
        __PaymentSplitter_init(_payees, _shares);

        contractURI = _contractURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual override {
        uint256 payment = _release(account);
        require(payment != 0, "PaymentSplitter: account is not due payment");
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual override {
        uint256 payment = _release(token, account);
        require(payment != 0, "PaymentSplitter: account is not due payment");
    }

    /// @dev Returns the amount of Ether that `account` is owed, according to their percentage of the total shares and returns the payment
    function _release(address payable account) internal returns (uint256) {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        if (payment == 0) {
            return 0;
        }

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);

        return payment;
    }

    /// @dev Returns the amount of `token` that `account` is owed, according to their percentage of the total shares and returns the payment
    function _release(IERC20Upgradeable token, address account) internal returns (uint256) {
        require(shares(account) > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        if (payment == 0) {
            return 0;
        }

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);

        return payment;
    }

    /**
     * @dev Release the owed amount of token to all of the payees.
     */
    function distribute() public virtual {
        uint256 count = payeeCount();
        for (uint256 i = 0; i < count; i++) {
            _release(payable(payee(i)));
        }
    }

    /**
     * @dev Release owed amount of the `token` to all of the payees.
     */
    function distribute(IERC20Upgradeable token) public virtual {
        uint256 count = payeeCount();
        for (uint256 i = 0; i < count; i++) {
            _release(token, payee(i));
        }
    }

    /// @dev See ERC2771
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See ERC2771
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }
}
