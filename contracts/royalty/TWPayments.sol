// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../ThirdwebFees.sol";

// Helper interfaces
import { IWETH } from "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TWPayments is IERC2981, Initializable {
    /// @dev Max bps in the thirdweb system
    uint256 public constant MAX_BPS = 10_000;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

    ThirdwebFees public immutable thirdwebFees;

    /// @dev The recipient of who gets the royalty.
    address public royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint256 public royaltyBps;

    /// @dev Emitted when the royalty recipient or fee bps is updated
    event NewRoyaltyuRecipient(address newRoyaltyRecipient);
    event RoyaltyUpdated(uint256 newRoyaltyBps);
    event EtherReceived(address sender, uint256 amount);
    event FundsWithdrawn(
        address indexed paymentReceiver,
        address feeRecipient,
        uint256 totalAmount,
        uint256 feeCollected
    );

    constructor(address _nativeTokenWrapper, address _thirdwebFees) {
        nativeTokenWrapper = _nativeTokenWrapper;
        thirdwebFees = ThirdwebFees(_thirdwebFees);
    }

    /// @dev Initializes the contract, like a constructor.
    function __TWPayments_init(address _receiver, uint256 _royaltyBps) internal onlyInitializing {
        __TWPayments_init_unchained(_receiver, _royaltyBps);
    }

    function __TWPayments_init_unchained(address _receiver, uint256 _royaltyBps) internal onlyInitializing {
        royaltyRecipient = _receiver;
        royaltyBps = _royaltyBps;
    }

    function withdrawFunds(address _currency) external {
        address recipient = royaltyRecipient;
        address feeRecipient = thirdwebFees.getRoyaltyFeeRecipient(address(this));

        uint256 totalTransferAmount = _currency == NATIVE_TOKEN
            ? address(this).balance
            : IERC20(_currency).balanceOf(_currency);
        uint256 fees = (totalTransferAmount * thirdwebFees.getRoyaltyFeeBps(address(this))) / MAX_BPS;

        transferCurrency(_currency, address(this), recipient, totalTransferAmount - fees);
        transferCurrency(_currency, address(this), feeRecipient, fees);

        emit FundsWithdrawn(recipient, feeRecipient, totalTransferAmount, fees);
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * @dev For setting NFT royalty recipient.
     *
     * @param _royaltyRecipient The address of which the payments goes to.
     */
    function _setRoyaltyRecipient(address _royaltyRecipient) internal {
        royaltyRecipient = _royaltyRecipient;
        emit NewRoyaltyuRecipient(_royaltyRecipient);
    }

    /**
     * @dev For setting royalty basis points.
     *
     * @param _royaltyBps the basis points of royalty. 10_000 = 100%.
     */
    function _setRoyaltyBps(uint256 _royaltyBps) internal {
        require(_royaltyBps <= 10_000, "exceed royalty bps");
        royaltyBps = _royaltyBps;
        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev See EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (salePrice * royaltyBps) / MAX_BPS;
        royaltyAmount += royaltyBps == 0 ? (salePrice * thirdwebFees.getRoyaltyFeeBps(address(this))) / MAX_BPS : 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId;
    }

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeToken(_to, _amount);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "Marketplace: native token value does not match bid amount.");
                IWETH(nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeToken(_to, _amount);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }
        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = _from == address(this)
            ? IERC20(_currency).transfer(_to, _amount)
            : IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && balAfter == balBefore + _amount, "Marketplace: failed to transfer currency.");
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(nativeTokenWrapper).deposit{ value: value }();
            safeTransferERC20(nativeTokenWrapper, address(this), to, value);
        }
    }
}