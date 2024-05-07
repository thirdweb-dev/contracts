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

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../../extension/Multicall.sol";

//  ==========  Internal imports    ==========

import "../../interface/airdrop/IAirdropERC20.sol";
import { CurrencyTransferLib } from "../../../lib/CurrencyTransferLib.sol";
import "../../../eip/interface/IERC20.sol";
import "../../../external-deps/openzeppelin/metatx/ERC2771ContextUpgradeable.sol";

//  ==========  Features    ==========
import "../../../extension/PermissionsEnumerable.sol";
import "../../../extension/ContractMetadata.sol";

contract AirdropERC20 is
    Initializable,
    ContractMetadata,
    PermissionsEnumerable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    Multicall,
    IAirdropERC20
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("AirdropERC20");
    uint256 private constant VERSION = 2;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders
    ) external initializer {
        __ERC2771Context_init_unchained(_trustedForwarders);

        _setupContractURI(_contractURI);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        __ReentrancyGuard_init();
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                            Airdrop logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets contract-owner send ERC20 tokens to a list of addresses.
     *  @dev             The token-owner should approve target tokens to Airdrop contract,
     *                   which acts as operator for the tokens.
     *
     *  @param _tokenAddress    The contract address of the tokens to transfer.
     *  @param _tokenOwner      The owner of the tokens to transfer.
     *  @param _contents        List containing recipient, tokenId and amounts to airdrop.
     */
    function airdropERC20(
        address _tokenAddress,
        address _tokenOwner,
        AirdropContent[] calldata _contents
    ) external payable nonReentrant {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized.");

        uint256 len = _contents.length;
        uint256 nativeTokenAmount;
        uint256 refundAmount;

        for (uint256 i = 0; i < len; ) {
            bool success = _transferCurrencyWithReturnVal(
                _tokenAddress,
                _tokenOwner,
                _contents[i].recipient,
                _contents[i].amount
            );

            if (!success) {
                emit AirdropFailed(_tokenAddress, _tokenOwner, _contents[i].recipient, _contents[i].amount);
            }

            if (_tokenAddress == CurrencyTransferLib.NATIVE_TOKEN) {
                nativeTokenAmount += _contents[i].amount;

                require(nativeTokenAmount <= msg.value, "Insufficient native token amount");

                if (!success) {
                    refundAmount += _contents[i].amount;
                }
            }

            unchecked {
                i += 1;
            }
        }

        require(nativeTokenAmount == msg.value, "Incorrect native token amount");

        if (refundAmount > 0) {
            // refund failed payments' amount to contract admin address
            CurrencyTransferLib.safeTransferNativeToken(msg.sender, refundAmount);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Transfers ERC20 tokens and returns a boolean i.e. the status of the transfer.
    function _transferCurrencyWithReturnVal(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool success) {
        if (_amount == 0) {
            success = true;
            return success;
        }

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            // solhint-disable avoid-low-level-calls
            // slither-disable-next-line low-level-calls
            (success, ) = _to.call{ value: _amount }("");
        } else {
            (bool success_, bytes memory data_) = _currency.call(
                abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _amount)
            );

            success = success_;
            if (!success || (data_.length > 0 && !abi.decode(data_, (bool)))) {
                success = false;

                require(
                    IERC20(_currency).balanceOf(_from) >= _amount &&
                        IERC20(_currency).allowance(_from, address(this)) >= _amount,
                    "Not balance or allowance"
                );
            }
        }
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC2771
    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, Multicall)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }
}
