// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

//  ==========  Feature imports    ==========//mychange
import "../feature/TokenBundle.sol";

//  ==========  Internal imports    ==========

import "./ITempPack.sol";
import "../interfaces/ITWFee.sol";

import "../interfaces/IThirdwebContract.sol";
import "../interfaces/IThirdwebOwnable.sol";
import "../interfaces/IThirdwebRoyalty.sol";

import "../openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "../lib/FeeType.sol";
import "../lib/CurrencyTransferLib.sol";

contract TempPack is
    Initializable,
    IThirdwebContract,
    IThirdwebOwnable,
    IThirdwebRoyalty,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    ERC1155PausableUpgradeable,
    ITempPack,
    TokenBundle
{

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant MODULE_TYPE = bytes32("Pack");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can create packs.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The thirdweb contract with fee related information.
    ITWFee public immutable thirdwebFee;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev The token Id of the next set of packs to be minted.
    // uint256 public nextTokenId;//mychange

    /// @dev The (default) address that receives all royalty value.
    address private royaltyRecipient;

    /// @dev The (default) % of a sale to take as royalty (in basis points).
    uint256 private royaltyBps;

    /// @dev Contract level metadata.
    string public contractURI;

    /*///////////////////////////////////////////////////////////////
                             Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from pack ID => royalty recipient and bps for the pack.
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /// @dev Mapping from token ID => total circulating supply of token with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Mapping from pack ID => The state of that set of packs.
    mapping(uint256 => PackInfo) private packInfo;

    //mychange
    mapping(uint256 => mapping(uint256 => uint256)) public unitAmountsPerTokenPerPack;

   /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(address _thirdwebFee, address _nativeTokenWrapper) initializer {
        thirdwebFee = ITWFee(_thirdwebFee);
        nativeTokenWrapper = _nativeTokenWrapper;
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
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155Pausable_init();
        __ERC1155_init(_contractURI);

        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = _royaltyBps;
        contractURI = _contractURI;

        _owner = _defaultAdmin;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
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

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Pauses / unpauses contract.
    function pause(bool _toPause) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        if(_toPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        // return packInfo[_tokenId].uri;//mychange
        return getUri(_tokenId);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155ReceiverUpgradeable, AccessControlEnumerableUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                    Pack logic: create | open packs.
    //////////////////////////////////////////////////////////////*/

    /// @dev Creates a pack with the stated contents.
    function createPack(
        PackContent[] calldata _contents,
        string calldata _packUri,
        uint128 _openStartTimestamp,
        uint128 _amountDistributedPerOpen,
        address _recipient
    )
        external
        onlyRole(MINTER_ROLE)
        nonReentrant
        whenNotPaused
        returns (uint256 packId, uint256 packTotalSupply)
    {

        require(_contents.length > 0, "nothing to pack");

        // packId = nextTokenId;
        // nextTokenId += 1;//mychange
        packId = _getNextTokenId();

        packTotalSupply = escrowPackContents(_contents, packId);//mychange

        // packInfo[packId].uri = _packUri;//mychange
        _setUri(_packUri, packId);
        packInfo[packId].openStartTimestamp = _openStartTimestamp;
        packInfo[packId].amountDistributedPerOpen = _amountDistributedPerOpen;

        _mint(_recipient, packId, packTotalSupply, "");

        emit PackCreated(packId, _msgSender(), _recipient, packInfo[packId], packTotalSupply);
    }

    /// @notice Lets a pack owner open packs and receive the packs' reward units.
    function openPack(uint256 _packId, uint256 _amountToOpen) external nonReentrant whenNotPaused {

        address opener = _msgSender();

        require(opener == tx.origin, "opener must be eoa");
        require(balanceOf(opener, _packId) >= _amountToOpen, "opening more than owned");

        PackInfo memory pack = packInfo[_packId];
        require(pack.openStartTimestamp < block.timestamp, "cannot open yet");

        (
            PackContent[] memory rewardUnits
        ) = getRewardUnits(_packId, _amountToOpen, pack.amountDistributedPerOpen); //mychange

        _burn(_msgSender(), _packId, _amountToOpen);

        for(uint256 i = 0; i < rewardUnits.length; i += 1) {
            //mychange
            transferPackContent(
                rewardUnits[i].token.assetContract,
                rewardUnits[i].token.tokenType,
                address(this),
                _msgSender(),
                rewardUnits[i].token.tokenId,
                rewardUnits[i].token.totalAmount
            );
        }

        emit PackOpened(_packId, _msgSender(), _amountToOpen, rewardUnits);
    }

    function escrowPackContents(
        PackContent[] calldata _contents,
        uint256 _packId
    )
        internal 
        returns (uint256 packTotalSupply) 
    {
        uint256 nativeTokenAmount;

        for(uint256 i = 0; i < _contents.length; i += 1) {

            require(_contents[i].token.totalAmount % _contents[i].amountPerUnit == 0, "invalid reward units");
            require(_contents[i].token.tokenType != TokenType.ERC721 || _contents[i].token.totalAmount == 1, "invalid erc721 rewards");

            packTotalSupply += _contents[i].token.totalAmount / _contents[i].amountPerUnit;
            // pack.contents.push(_contents[i]);//mychange
            _setBundleToken(_contents[i].token, _packId, i);
            unitAmountsPerTokenPerPack[_packId][i] = _contents[i].amountPerUnit;

            if(_contents[i].token.assetContract == CurrencyTransferLib.NATIVE_TOKEN) {
                nativeTokenAmount += _contents[i].token.totalAmount;
            } else {
                transferPackContent(
                    _contents[i].token.assetContract, 
                    _contents[i].token.tokenType,
                    _msgSender(),
                    address(this),
                    _contents[i].token.tokenId,
                    _contents[i].token.totalAmount
                );
            }
        }

        if(nativeTokenAmount > 0) {
            transferPackContent(
                CurrencyTransferLib.NATIVE_TOKEN, 
                TokenType.ERC20,
                _msgSender(),
                address(this),
                0,
                nativeTokenAmount
            );
        }
    }

    /// @dev Returns the reward units to distribute.
    function getRewardUnits(
        uint256 _packId,
        uint256 _numOfPacksToOpen,
        uint256 _rewardUnitsPerOpen
    )   
        internal
        returns (
            PackContent[] memory rewardUnits
        ) 
    {

        rewardUnits = new PackContent[](_numOfPacksToOpen * _rewardUnitsPerOpen);
        uint256 currentTotalSupply = totalSupply[_packId];

        uint256 random = uint(keccak256(abi.encodePacked(_msgSender(), blockhash(block.number), block.difficulty)));
        for(uint256 i = 0; i < (_numOfPacksToOpen * _rewardUnitsPerOpen); i += 1) {
            
            uint256 randomVal = uint256(keccak256(abi.encode(random, i)));
            uint256 target = randomVal % currentTotalSupply;
            uint256 step;
            uint256 count = getTokenCount(_packId);

            for(uint256 j = 0; j < count; j += 1) {
                //mychange
                Token memory token = getToken(_packId, j);
                uint256 check = token.totalAmount / unitAmountsPerTokenPerPack[_packId][j];

                if(target < step + check) {

                    rewardUnits[i].token = token;
                    rewardUnits[i].token.totalAmount = unitAmountsPerTokenPerPack[_packId][j];

                    token.totalAmount -= unitAmountsPerTokenPerPack[_packId][j];
                    // packInfo[_packId].contents[j].totalAmountPacked -= _availableRewardUnits[j].amountPerUnit;
                    _updateBundleToken(token, _packId, j);

                    break;

                } else {
                    step += check;
                }
            }
        }
    }

    /// @dev Transfers an arbitrary ERC20 / ERC721 / ERC1155 token.
    function transferPackContent(
        address _assetContract,
        TokenType _tokenType,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        if (_tokenType == TokenType.ERC20) {
            CurrencyTransferLib.transferCurrencyWithWrapperAndBalanceCheck(
                _assetContract,
                _from,
                _to,
                _amount,
                nativeTokenWrapper
            );
        } else if (_tokenType == TokenType.ERC721) {
            IERC721Upgradeable(_assetContract).safeTransferFrom(_from, _to, _tokenId);
        } else if (_tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(_assetContract).safeTransferFrom(_from, _to, _tokenId, _amount, "");
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Getter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    

    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= MAX_BPS, "exceed royalty bps");

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        emit OwnerUpdated(_owner, _newOwner);
        _owner = _newOwner;
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
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

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
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