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

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

//  ==========  Internal imports    ==========

import "../../interfaces/IPackVRFDirect.sol";
import "../../lib/TWStrings.sol";
import "../../lib/CurrencyTransferLib.sol";
import { IERC2981 } from "../../eip/interface/IERC2981.sol";
import { IERC721Receiver } from "../../eip/interface/IERC721Receiver.sol";
import { Context, ERC1155Upgradeable } from "../../dynamic-contracts/eip/ERC1155Upgradeable.sol";
import { IERC2771Context } from "../../extension/interface/IERC2771Context.sol";
import { ERC1155Storage } from "../../dynamic-contracts/eip/ERC1155Upgradeable.sol";
import { PackVRFDirectStorage } from "./PackVRFDirectStorage.sol";

//  ==========  Features    ==========

import { TokenStore, ERC1155Receiver } from "../../dynamic-contracts/extension/TokenStore.sol";
import { ERC2771ContextUpgradeable } from "../../dynamic-contracts/extension/ERC2771ContextUpgradeable.sol";
import { Royalty, IERC165 } from "../../dynamic-contracts/extension/Royalty.sol";
import { ContractMetadata } from "../../dynamic-contracts/extension/ContractMetadata.sol";
import { Ownable } from "../../dynamic-contracts/extension/Ownable.sol";
import { ReentrancyGuard } from "../../dynamic-contracts/extension/ReentrancyGuard.sol";
import { DefaultOperatorFiltererUpgradeable } from "../../dynamic-contracts/extension/DefaultOperatorFiltererUpgradeable.sol";
import { PermissionsStorage } from "../../dynamic-contracts/extension/Permissions.sol";

contract PackVRFDirectLogic is
    VRFV2WrapperConsumerBase,
    Royalty,
    ContractMetadata,
    Ownable,
    TokenStore,
    DefaultOperatorFiltererUpgradeable,
    ERC2771ContextUpgradeable,
    ERC1155Upgradeable,
    IPackVRFDirect,
    ReentrancyGuard
{
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 private constant DEFAULT_ADMIN_ROLE = 0x00;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only transfers initiated by operator role hodlers are valid, when operator-initated transfers are restricted.
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*///////////////////////////////////////////////////////////////
                            VRF state
    //////////////////////////////////////////////////////////////*/

    uint32 private constant CALLBACKGASLIMIT = 100_000;
    uint16 private constant REQUEST_CONFIRMATIONS = 5;
    uint32 private constant NUMWORDS = 1;

    /// @dev Emitted when admin deposits Link tokens.
    event LinkTokensDepositedByAdmin(uint256 amount);

    /// @dev Emitted when admin withdrwas deposited Link tokens.
    event LinkTokensWithdrawnByAdmin(uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _nativeTokenWrapper,
        address _linkTokenAddress,
        address _vrfV2Wrapper
    ) VRFV2WrapperConsumerBase(_linkTokenAddress, _vrfV2Wrapper) TokenStore(_nativeTokenWrapper) {}

    /*///////////////////////////////////////////////////////////////
                        Deposit / Withdraw LINK
    //////////////////////////////////////////////////////////////*/

    /// @dev Admin deposits Link tokens.
    /// Must use this function. Direct transfers will not be recoverable.
    function depositLinkTokens(uint256 _amount) external payable nonReentrant {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");

        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        uint256 balanceBefore = LINK.balanceOf(address(this));
        CurrencyTransferLib.transferCurrency(address(LINK), _msgSender(), address(this), _amount);
        uint256 actualAmount = LINK.balanceOf(address(this)) - balanceBefore;

        packVrfData.linkBalance += actualAmount;

        emit LinkTokensDepositedByAdmin(actualAmount);
    }

    /// @dev Admin can withdraw unused/excess Link tokens.
    function withdrawLinkTokens(uint256 _amount) external nonReentrant {
        require(_hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        require(packVrfData.linkBalance >= _amount, "Insufficient LINK balance");
        packVrfData.linkBalance -= _amount;

        CurrencyTransferLib.transferCurrency(address(LINK), address(this), _msgSender(), _amount);

        emit LinkTokensWithdrawnByAdmin(_amount);
    }

    /// @notice View total Link available in the contract.
    function getLinkBalance() external view returns (uint256) {
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();
        return packVrfData.linkBalance;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return getUriOfBundle(_tokenId);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, ERC1155Upgradeable, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981).interfaceId == interfaceId ||
            type(IERC721Receiver).interfaceId == interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                    Pack logic: create | open packs.
    //////////////////////////////////////////////////////////////*/

    /// @dev Creates a pack with the stated contents.
    function createPack(
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits,
        string memory _packUri,
        uint128 _openStartTimestamp,
        uint128 _amountDistributedPerOpen,
        address _recipient
    ) external payable nonReentrant returns (uint256 packId, uint256 packTotalSupply) {
        require(_hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        require(_contents.length > 0 && _contents.length == _numOfRewardUnits.length, "!Len");

        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        packId = packVrfData.nextTokenIdToMint;
        packVrfData.nextTokenIdToMint += 1;

        packTotalSupply = escrowPackContents(
            _contents,
            _numOfRewardUnits,
            _packUri,
            packId,
            _amountDistributedPerOpen,
            false
        );

        packVrfData.packInfo[packId].openStartTimestamp = _openStartTimestamp;
        packVrfData.packInfo[packId].amountDistributedPerOpen = _amountDistributedPerOpen;

        _mint(_recipient, packId, packTotalSupply, "");

        emit PackCreated(packId, _recipient, packTotalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                            VRF logic
    //////////////////////////////////////////////////////////////*/

    function openPackAndClaimRewards(
        uint256 _packId,
        uint256 _amountToOpen,
        uint32 _callBackGasLimit
    ) external returns (uint256) {
        return _requestOpenPack(_packId, _amountToOpen, _callBackGasLimit, true);
    }

    /// @notice Lets a pack owner open packs and receive the packs' reward units.
    function openPack(uint256 _packId, uint256 _amountToOpen) external returns (uint256) {
        return _requestOpenPack(_packId, _amountToOpen, CALLBACKGASLIMIT, false);
    }

    function _requestOpenPack(
        uint256 _packId,
        uint256 _amountToOpen,
        uint32 _callBackGasLimit,
        bool _openOnFulfill
    ) internal returns (uint256 requestId) {
        address opener = _msgSender();
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        require(isTrustedForwarder(msg.sender) || opener == tx.origin, "!EOA");

        require(packVrfData.openerToReqId[opener] == 0, "ReqInFlight");

        require(_amountToOpen > 0 && balanceOf(opener, _packId) >= _amountToOpen, "!Bal");
        require(packVrfData.packInfo[_packId].openStartTimestamp <= block.timestamp, "!Open");

        // Transfer packs into the contract.
        _safeTransferFrom(opener, address(this), _packId, _amountToOpen, "");

        // Ensure the contract has sufficient LINK available to request randomness
        uint256 requestPrice = VRF_V2_WRAPPER.calculateRequestPrice(_callBackGasLimit);
        require(packVrfData.linkBalance >= requestPrice, "Insufficient LINK balance");

        // Request VRF for randomness.
        uint16 requestConfirmations = (block.chainid == 137 || block.chainid == 80001) ? 15 : REQUEST_CONFIRMATIONS;
        requestId = requestRandomness(_callBackGasLimit, requestConfirmations, NUMWORDS);
        require(requestId > 0, "!VRF");

        // Mark request as active; store request parameters.
        packVrfData.requestInfo[requestId].packId = _packId;
        packVrfData.requestInfo[requestId].opener = opener;
        packVrfData.requestInfo[requestId].amountToOpen = _amountToOpen;
        packVrfData.requestInfo[requestId].openOnFulfillRandomness = _openOnFulfill;
        packVrfData.openerToReqId[opener] = requestId;

        emit PackOpenRequested(opener, _packId, _amountToOpen, requestId);
    }

    /// @notice Called by Chainlink VRF to fulfill a random number request.
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();
        RequestInfo memory info = packVrfData.requestInfo[_requestId];

        require(info.randomWords.length == 0, "!Req");
        packVrfData.requestInfo[_requestId].randomWords = _randomWords;

        emit PackRandomnessFulfilled(info.packId, _requestId);

        if (info.openOnFulfillRandomness) {
            try PackVRFDirectLogic(payable(address(this))).sendRewardsIndirect(info.opener) {} catch {}
        }
    }

    /// @notice Returns whether a pack opener is ready to call `claimRewards`.
    function canClaimRewards(address _opener) public view returns (bool) {
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();
        uint256 requestId = packVrfData.openerToReqId[_opener];
        return requestId > 0 && packVrfData.requestInfo[requestId].randomWords.length > 0;
    }

    /// @notice Lets a pack owner open packs and receive the packs' reward units.
    function claimRewards() external returns (Token[] memory) {
        return _claimRewards(_msgSender());
    }

    /// @notice Lets a pack owner open packs and receive the packs' reward units.
    function sendRewardsIndirect(address _opener) external {
        require(msg.sender == address(this));
        _claimRewards(_opener);
    }

    function _claimRewards(address opener) internal returns (Token[] memory) {
        require(isTrustedForwarder(msg.sender) || opener == tx.origin, "!EOA");

        require(canClaimRewards(opener), "!ActiveReq");
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        uint256 reqId = packVrfData.openerToReqId[opener];
        RequestInfo memory info = packVrfData.requestInfo[reqId];

        delete packVrfData.openerToReqId[opener];
        delete packVrfData.requestInfo[reqId];

        PackInfo memory pack = packVrfData.packInfo[info.packId];

        Token[] memory rewardUnits = getRewardUnits(
            info.randomWords[0],
            info.packId,
            info.amountToOpen,
            pack.amountDistributedPerOpen,
            pack
        );

        // Burn packs.
        _burn(address(this), info.packId, info.amountToOpen);

        _transferTokenBatch(address(this), opener, rewardUnits);

        emit PackOpened(info.packId, opener, info.amountToOpen, rewardUnits);

        return rewardUnits;
    }

    /// @dev Stores assets within the contract.
    function escrowPackContents(
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits,
        string memory _packUri,
        uint256 packId,
        uint256 amountPerOpen,
        bool isUpdate
    ) internal returns (uint256 supplyToMint) {
        uint256 sumOfRewardUnits;
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        for (uint256 i = 0; i < _contents.length; i += 1) {
            require(_contents[i].totalAmount != 0, "0 amt");
            require(_contents[i].totalAmount % _numOfRewardUnits[i] == 0, "!R");
            require(_contents[i].tokenType != TokenType.ERC721 || _contents[i].totalAmount == 1, "!R");

            sumOfRewardUnits += _numOfRewardUnits[i];

            packVrfData.packInfo[packId].perUnitAmounts.push(_contents[i].totalAmount / _numOfRewardUnits[i]);
        }

        require(sumOfRewardUnits % amountPerOpen == 0, "!Amt");
        supplyToMint = sumOfRewardUnits / amountPerOpen;

        if (isUpdate) {
            for (uint256 i = 0; i < _contents.length; i += 1) {
                _addTokenInBundle(_contents[i], packId);
            }
            _transferTokenBatch(_msgSender(), address(this), _contents);
        } else {
            _storeTokens(_msgSender(), _contents, _packUri, packId);
        }
    }

    /// @dev Returns the reward units to distribute.
    function getRewardUnits(
        uint256 _random,
        uint256 _packId,
        uint256 _numOfPacksToOpen,
        uint256 _rewardUnitsPerOpen,
        PackInfo memory pack
    ) internal returns (Token[] memory rewardUnits) {
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        uint256 numOfRewardUnitsToDistribute = _numOfPacksToOpen * _rewardUnitsPerOpen;
        rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        uint256 totalRewardUnits = packVrfData.totalSupply[_packId] * _rewardUnitsPerOpen;
        uint256 totalRewardKinds = getTokenCountOfBundle(_packId);

        (Token[] memory _token, ) = getPackContents(_packId);
        bool[] memory _isUpdated = new bool[](totalRewardKinds);
        for (uint256 i = 0; i < numOfRewardUnitsToDistribute; i += 1) {
            uint256 randomVal = uint256(keccak256(abi.encode(_random, i)));
            uint256 target = randomVal % totalRewardUnits;
            uint256 step;

            for (uint256 j = 0; j < totalRewardKinds; j += 1) {
                uint256 totalRewardUnitsOfKind = _token[j].totalAmount / pack.perUnitAmounts[j];

                if (target < step + totalRewardUnitsOfKind) {
                    _token[j].totalAmount -= pack.perUnitAmounts[j];
                    _isUpdated[j] = true;

                    rewardUnits[i].assetContract = _token[j].assetContract;
                    rewardUnits[i].tokenType = _token[j].tokenType;
                    rewardUnits[i].tokenId = _token[j].tokenId;
                    rewardUnits[i].totalAmount = pack.perUnitAmounts[j];

                    totalRewardUnits -= 1;

                    break;
                } else {
                    step += totalRewardUnitsOfKind;
                }
            }
        }

        for (uint256 i = 0; i < totalRewardKinds; i += 1) {
            if (_isUpdated[i]) {
                _updateTokenInBundle(_token[i], _packId, i);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the underlying contents of a pack.
    function getPackContents(uint256 _packId)
        public
        view
        returns (Token[] memory contents, uint256[] memory perUnitAmounts)
    {
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        PackInfo memory pack = packVrfData.packInfo[_packId];
        uint256 total = getTokenCountOfBundle(_packId);
        contents = new Token[](total);
        perUnitAmounts = new uint256[](total);

        for (uint256 i = 0; i < total; i += 1) {
            contents[i] = getTokenOfBundle(_packId, i);
        }
        perUnitAmounts = pack.perUnitAmounts;
    }

    function nextTokenIdToMint() external view returns (uint256) {
        PackVRFDirectStorage.Data storage data = PackVRFDirectStorage.packVRFStorage();
        return data.nextTokenIdToMint;
    }

    function totalSupply(uint256 _tokenId) external view returns (uint256) {
        PackVRFDirectStorage.Data storage data = PackVRFDirectStorage.packVRFStorage();
        return data.totalSupply[_tokenId];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether the operator restriction can be set within the given execution context.
    function _canSetOperatorRestriction() internal virtual override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        PackVRFDirectStorage.Data storage packVrfData = PackVRFDirectStorage.packVRFStorage();

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                packVrfData.totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                packVrfData.totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function _hasRole(bytes32 role, address addr) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        return data._hasRole[role][addr];
    }

    function _hasRoleWithSwitch(bytes32 role, address account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.permissionsStorage();
        if (!data._hasRole[role][address(0)]) {
            return data._hasRole[role][account];
        }

        return true;
    }

    function _msgSender() internal view override(Context, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
