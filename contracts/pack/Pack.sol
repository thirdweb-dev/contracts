// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IPack.sol";
import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

//  ==========  Features    ==========

import "../extension/ContractMetadata.sol";
import "../extension/Royalty.sol";
import "../extension/Ownable.sol";
import "../extension/PermissionsEnumerable.sol";
import { TokenStore, ERC1155Receiver } from "../extension/TokenStore.sol";

contract Pack is
    Initializable,
    ContractMetadata,
    Ownable,
    Royalty,
    PermissionsEnumerable,
    TokenStore,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155Upgradeable,
    IPack
{
    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("Pack");
    uint256 private constant VERSION = 2;

    address private immutable forwarder;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private transferRole;

    /// @dev Only MINTER_ROLE holders can create packs.
    bytes32 private minterRole;

    /// @dev Only assets with ASSET_ROLE can be packed, when packing is restricted to particular assets.
    bytes32 private assetRole;

    /// @dev The token Id of the next set of packs to be minted.
    uint256 public nextTokenIdToMint;

    /*///////////////////////////////////////////////////////////////
                             Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from token ID => total circulating supply of token with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Mapping from pack ID => The state of that set of packs.
    mapping(uint256 => PackInfo) private packInfo;

    /// @dev Checks if pack-creator allowed to add more tokens to a packId; set to false after first transfer
    mapping(uint256 => bool) public canUpdatePack;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _nativeTokenWrapper, address _trustedForwarder) TokenStore(_nativeTokenWrapper) initializer {
        forwarder = _trustedForwarder;
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external initializer {
        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");
        bytes32 _assetRole = keccak256("ASSET_ROLE");

        /** note:  The immutable state-variable `forwarder` is an EOA-only forwarder,
         *         which guards against automated attacks.
         *
         *         Use other forwarders only if there's a strong reason to bypass this check.
         */
        address[] memory forwarders = new address[](_trustedForwarders.length + 1);
        uint256 i;
        for (; i < _trustedForwarders.length; i++) {
            forwarders[i] = _trustedForwarders[i];
        }
        forwarders[i] = forwarder;
        __ERC2771Context_init(forwarders);
        __ERC1155_init(_contractURI);

        name = _name;
        symbol = _symbol;

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));

        // note: see `onlyRoleWithSwitch` for ASSET_ROLE behaviour.
        _setupRole(_assetRole, address(0));

        _setupDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        transferRole = _transferRole;
        minterRole = _minterRole;
        assetRole = _assetRole;
    }

    receive() external payable {
        require(msg.sender == nativeTokenWrapper, "!nativeTokenWrapper.");
    }

    /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyRoleWithSwitch(bytes32 role) {
        _checkRoleWithSwitch(role, _msgSender());
        _;
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
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            type(IERC721Receiver).interfaceId == interfaceId ||
            type(IERC1155Receiver).interfaceId == interfaceId;
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
    ) external payable onlyRoleWithSwitch(minterRole) nonReentrant returns (uint256 packId, uint256 packTotalSupply) {
        require(_contents.length > 0 && _contents.length == _numOfRewardUnits.length, "!Len");

        if (!hasRole(assetRole, address(0))) {
            for (uint256 i = 0; i < _contents.length; i += 1) {
                _checkRole(assetRole, _contents[i].assetContract);
            }
        }

        packId = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        packTotalSupply = escrowPackContents(
            _contents,
            _numOfRewardUnits,
            _packUri,
            packId,
            _amountDistributedPerOpen,
            false
        );

        packInfo[packId].openStartTimestamp = _openStartTimestamp;
        packInfo[packId].amountDistributedPerOpen = _amountDistributedPerOpen;

        canUpdatePack[packId] = true;

        _mint(_recipient, packId, packTotalSupply, "");

        emit PackCreated(packId, _recipient, packTotalSupply);
    }

    /// @dev Add contents to an existing packId.
    function addPackContents(
        uint256 _packId,
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits,
        address _recipient
    )
        external
        payable
        onlyRoleWithSwitch(minterRole)
        nonReentrant
        returns (uint256 packTotalSupply, uint256 newSupplyAdded)
    {
        require(canUpdatePack[_packId], "!Allowed");
        require(_contents.length > 0 && _contents.length == _numOfRewardUnits.length, "!Len");
        require(balanceOf(_recipient, _packId) != 0, "!Bal");

        if (!hasRole(assetRole, address(0))) {
            for (uint256 i = 0; i < _contents.length; i += 1) {
                _checkRole(assetRole, _contents[i].assetContract);
            }
        }

        uint256 amountPerOpen = packInfo[_packId].amountDistributedPerOpen;

        newSupplyAdded = escrowPackContents(_contents, _numOfRewardUnits, "", _packId, amountPerOpen, true);
        packTotalSupply = totalSupply[_packId] + newSupplyAdded;

        _mint(_recipient, _packId, newSupplyAdded, "");

        emit PackUpdated(_packId, _recipient, newSupplyAdded);
    }

    /// @notice Lets a pack owner open packs and receive the packs' reward units.
    function openPack(uint256 _packId, uint256 _amountToOpen) external returns (Token[] memory) {
        address opener = _msgSender();

        require(isTrustedForwarder(msg.sender) || opener == tx.origin, "!EOA");
        require(balanceOf(opener, _packId) >= _amountToOpen, "!Bal");

        PackInfo memory pack = packInfo[_packId];
        require(pack.openStartTimestamp <= block.timestamp, "cant open");

        Token[] memory rewardUnits = getRewardUnits(_packId, _amountToOpen, pack.amountDistributedPerOpen, pack);

        _burn(opener, _packId, _amountToOpen);

        _transferTokenBatch(address(this), opener, rewardUnits);

        emit PackOpened(_packId, opener, _amountToOpen, rewardUnits);

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

        for (uint256 i = 0; i < _contents.length; i += 1) {
            require(_contents[i].totalAmount != 0, "0 amt");
            require(_contents[i].totalAmount % _numOfRewardUnits[i] == 0, "!R");
            require(_contents[i].tokenType != TokenType.ERC721 || _contents[i].totalAmount == 1, "!R");

            sumOfRewardUnits += _numOfRewardUnits[i];

            packInfo[packId].perUnitAmounts.push(_contents[i].totalAmount / _numOfRewardUnits[i]);
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
        uint256 _packId,
        uint256 _numOfPacksToOpen,
        uint256 _rewardUnitsPerOpen,
        PackInfo memory pack
    ) internal returns (Token[] memory rewardUnits) {
        uint256 numOfRewardUnitsToDistribute = _numOfPacksToOpen * _rewardUnitsPerOpen;
        rewardUnits = new Token[](numOfRewardUnitsToDistribute);
        uint256 totalRewardUnits = totalSupply[_packId] * _rewardUnitsPerOpen;
        uint256 totalRewardKinds = getTokenCountOfBundle(_packId);

        uint256 random = generateRandomValue();

        (Token[] memory _token, ) = getPackContents(_packId);
        bool[] memory _isUpdated = new bool[](totalRewardKinds);
        for (uint256 i = 0; i < numOfRewardUnitsToDistribute; i += 1) {
            uint256 randomVal = uint256(keccak256(abi.encode(random, i)));
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
        PackInfo memory pack = packInfo[_packId];
        uint256 total = getTokenCountOfBundle(_packId);
        contents = new Token[](total);
        perUnitAmounts = new uint256[](total);

        for (uint256 i = 0; i < total; i += 1) {
            contents[i] = getTokenOfBundle(_packId, i);
        }
        perUnitAmounts = pack.perUnitAmounts;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    function generateRandomValue() internal view returns (uint256 random) {
        random = uint256(keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1), block.difficulty)));
    }

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

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(transferRole, from) || hasRole(transferRole, to), "!TRANSFER_ROLE");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        } else {
            for (uint256 i = 0; i < ids.length; ++i) {
                // pack can no longer be updated after first transfer to non-zero address
                if (canUpdatePack[ids[i]] && amounts[i] != 0) {
                    canUpdatePack[ids[i]] = false;
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev See EIP-2771
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /// @dev See EIP-2771
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
