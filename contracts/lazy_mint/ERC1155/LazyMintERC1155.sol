// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ILazyMintERC1155 } from "./ILazyMintERC1155.sol";

// Token
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// Protocol control center.
import { ProtocolControl } from "../../ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Access Control + security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Utils
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract LazyMintERC1155 is

    ILazyMintERC1155,
    ERC1155,
    ERC2771Context,
    IERC2981,    
    AccessControlEnumerable,
    Pausable,
    ReentrancyGuard,    
    Multicall    

{
    using Strings for uint256;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs (i.e. can call functions prefixed with `lazyMint`).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 public nextTokenIdToMint;

    /// @dev Contract interprets 10_000 as 100%.
    uint64 private constant MAX_BPS = 10_000;

    /// @dev The % of secondary sales collected as royalties. See EIP 2981.
    uint64 public royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint120 public feeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    uint[] private baseURIIndices;
    
    /// @dev End token Id => URI that overrides `baseURI + tokenId` convention.
    mapping(uint256 => string) private baseURI;
    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;
    /// @dev Token ID => public mint conditions for tokens with that ID.
    mapping(uint256 => PublicMintConditions) public mintConditions;
    /// @dev Token ID => the address of the recipient of primary sales.
    mapping(uint256 => address) public saleRecipient;

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE on the protocol control center.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.DEFAULT_ADMIN_ROLE(), _msgSender()), 
            "LazyMintERC1155: not protocol admin."
        );
        _;
    }

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LazyMintERC1155: not module admin.");
        _;
    }

    /// @dev Checks whether caller has MINTER_ROLE.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "LazyMintERC1155: not minter.");
        _;
    }

    constructor(
        string memory _contractURI,
        address payable _controlCenter,
        address _trustedForwarder,
        address _nativeTokenWrapper,
        address _saleRecipient
    ) 
        ERC1155("")
        ERC2771Context(_trustedForwarder)
    {
        
        controlCenter = ProtocolControl(_controlCenter);
        nativeTokenWrapper = _nativeTokenWrapper;
        defaultSaleRecipient = _saleRecipient;
        contractURI = _contractURI;

        address deployer = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);
        _setupRole(TRANSFER_ROLE, deployer);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {

        for(uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if(_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }
        
        return "";
    }

    ///     =====   External functions  =====

    /**
     *  @dev Lets an account with `MINTER_ROLE` mint tokens of ID from `nextTokenIdToMint` 
     *       to `nextTokenIdToMint + _amount - 1`. The URIs for these tokenIds is baseURI + `${tokenId}`.
     */
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external onlyMinter {
        uint256 startId = nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

        nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);
        
        emit LazyMintedTokens(startId , startId + _amount - 1, _baseURIForTokens);
    }
    
    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId.
    function claim(
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) 
        external
        payable
        nonReentrant 
        whenNotPaused
    {
        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition(_tokenId);
        MintCondition memory mintCondition = mintConditions[_tokenId].mintConditionAtIndex[activeConditionIndex];

        // Verify claim validity. If not valid, revert.
        verifyClaimIsValid(
            _tokenId,
            _quantity,
            _proofs,
            activeConditionIndex,
            mintCondition
        );

        // If there's a price, collect price.        
        collectClaimPrice(mintCondition, _quantity, _tokenId);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(mintCondition, activeConditionIndex, _tokenId, _quantity);
        
        emit ClaimedTokens(activeConditionIndex, _tokenId, _msgSender(), _quantity);
    }

    /// @dev Lets a module admin set mint conditions for a given tokenId.
    function setPublicMintConditions(
        uint256 _tokenId, 
        MintCondition[] calldata _conditions
    ) 
        external
        onlyModuleAdmin 
    {
        // make sure the conditions are sorted in ascending order
        uint256 lastConditionStartTimestamp = 0;
        uint256 indexForCondition = mintConditions[_tokenId].nextConditionIndex;

        for (uint256 i = 0; i < _conditions.length; i++) {
            
            require(
                lastConditionStartTimestamp == 0 
                    || lastConditionStartTimestamp < _conditions[i].startTimestamp,
                "LazyMintERC1155: startTimestamp must be in ascending order."
            );
            require(_conditions[i].maxMintSupply > 0, "LazyMintERC1155: max mint supply cannot be 0.");
            require(_conditions[i].quantityLimitPerTransaction > 0, "LazyMintERC1155: quantity limit cannot be 0.");

            mintConditions[_tokenId].mintConditionAtIndex[indexForCondition] = MintCondition({
                startTimestamp: _conditions[i].startTimestamp,
                maxMintSupply: _conditions[i].maxMintSupply,
                currentMintSupply: 0,
                quantityLimitPerTransaction: _conditions[i].quantityLimitPerTransaction,
                waitTimeInSecondsBetweenClaims: _conditions[i].waitTimeInSecondsBetweenClaims,
                pricePerToken: _conditions[i].pricePerToken,
                currency: _conditions[i].currency,
                merkleRoot: _conditions[i].merkleRoot
            });

            indexForCondition += 1;
            lastConditionStartTimestamp = _conditions[i].startTimestamp;
        }

        mintConditions[_tokenId].nextConditionIndex = indexForCondition;

        emit NewMintConditions(_tokenId, _conditions);
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = controlCenter.getRoyaltyTreasury(address(this));
        royaltyAmount = (salePrice * royaltyBps) / MAX_BPS;
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient, type(uint256).max, true);
    }

    /// @dev Lets a module admin set the recipient of all primary sales for a given token ID.
    function setSaleRecipient(uint256 _tokenId, address _saleRecipient) external onlyModuleAdmin {
        saleRecipient[_tokenId] = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient, _tokenId, false);
    }

    /// @dev Lets a module admin pause or unpause the contract.
    function setPaused(bool _toPause) external onlyModuleAdmin {
        if(_toPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "LazyMintERC1155: bps <= 10000.");

        royaltyBps = uint64(_royaltyBps);

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setFeeBps(uint256 _feeBps) public onlyModuleAdmin {
        require(_feeBps <= MAX_BPS, "LazyMintERC1155: bps <= 10000.");

        feeBps = uint120(_feeBps);

        emit PrimarySalesFeeUpdates(_feeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        emit TransfersRestricted(_restrictedTransfer);
    }
    
     /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyProtocolAdmin {
        contractURI = _uri;
    }

    //      =====   Getter functions  =====

    /// @dev Returns the current active mint condition for a given tokenId.
    function getTimesForNextValidClaim(
        uint256 _tokenId,
        uint256 _index,
        address _claimer
    )
        external
        view
        returns (uint256)
    {
        return mintConditions[_tokenId].nextValidTimestampForClaim[_claimer][_index];
    }

    /// @dev Returns the  mint condition for a given tokenId, at the given index.
    function getMintConditionAtIndex(
        uint256 _tokenId,
        uint256 _index
    )
        external
        view
        returns (MintCondition memory mintCondition)
    {
        mintCondition = mintConditions[_tokenId].mintConditionAtIndex[_index];
    }

    //      =====   Internal functions  =====

    /// @dev At any given moment, returns the uid for the active mint condition for a given tokenId.
    function getIndexOfActiveCondition(uint256 _tokenId) internal view returns (uint256) {

        uint256 nextConditionIndex = mintConditions[_tokenId].nextConditionIndex;

        require(nextConditionIndex > 0, "LazyMintERC1155: no public mint condition.");

        for (uint256 i = nextConditionIndex; i > 0; i -= 1) {
            if (block.timestamp >= mintConditions[_tokenId].mintConditionAtIndex[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("LazyMintERC1155: no active mint condition.");
    }

    /// @dev Checks whether a request to claim tokens obeys the active mint condition.
    function verifyClaimIsValid(
        uint256 _tokenId, 
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _conditionIndex,
        MintCondition memory _mintCondition
    )
        internal
        view
    {
        require(
            _quantity > 0 
                && _quantity <= _mintCondition.quantityLimitPerTransaction, 
            "LazyMintERC1155: invalid quantity claimed."
        );        
        require(
            _mintCondition.currentMintSupply + _quantity <= _mintCondition.maxMintSupply,
            "LazyMintERC1155: exceed max mint supply."
        );

        uint256 validTimestampForClaim = mintConditions[_tokenId].nextValidTimestampForClaim[_msgSender()][_conditionIndex];
        require(
            validTimestampForClaim == 0 
                || block.timestamp >= validTimestampForClaim, 
                "LazyMintERC1155: cannot claim yet."
        );

        if (_mintCondition.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(
                MerkleProof.verify(_proofs, _mintCondition.merkleRoot, leaf), 
                "LazyMintERC1155: not in whitelist."
            );
        }
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(
        MintCondition memory _mintCondition,
        uint256 _quantityToClaim,
        uint256 _tokenId
    )
        internal
    {
        if (_mintCondition.pricePerToken <= 0) {
            return;    
        }

        uint256 totalPrice = _quantityToClaim * _mintCondition.pricePerToken;
        uint256 fees = (totalPrice * feeBps) / MAX_BPS;

        if(_mintCondition.currency == NATIVE_TOKEN) {
            require(
                msg.value == totalPrice,
                "LazyMintERC1155: must send total price."
            );
        } else {
            validateERC20BalAndAllowance(
                _msgSender(), 
                _mintCondition.currency,
                totalPrice
            );
        }

        transferCurrency(
            _mintCondition.currency,
            _msgSender(),
            controlCenter.getRoyaltyTreasury(address(this)),
            fees
        );
        
        address recipient = saleRecipient[_tokenId];
        transferCurrency(
            _mintCondition.currency,
            _msgSender(),
            recipient == address(0) ? defaultSaleRecipient : recipient,
            totalPrice - fees
        );
    }

    /// @dev Transfers the tokens being claimed.
    function transferClaimedTokens(
        MintCondition memory _mintCondition,
        uint256 _mintConditionIndex,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    )
        internal
    {
        _mint(_msgSender(), _tokenId, _quantityBeingClaimed, "");

        // Update the supply minted under mint condition.
        mintConditions[_tokenId].mintConditionAtIndex[_mintConditionIndex].currentMintSupply += _quantityBeingClaimed;
        // Update the claimer's next valid timestamp to mint
        mintConditions[_tokenId].nextValidTimestampForClaim[_msgSender()][_mintConditionIndex] = block.timestamp + _mintCondition.waitTimeInSecondsBetweenClaims;
    }

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                IWETH(nativeTokenWrapper).withdraw(_amount);

                if (!safeTransferNativeToken(_to, _amount)) {
                    IWETH(nativeTokenWrapper).deposit{ value: _amount }();
                    safeTransferERC20(_currency, address(this), _to, _amount);
                }
            } else if (_to == address(this)) {
                require(_amount == msg.value, "LazyMintERC1155: native token value does not match bid amount.");
                IWETH(nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                if (!safeTransferNativeToken(_to, _amount)) {
                    IWETH(nativeTokenWrapper).deposit{ value: _amount }();
                    safeTransferERC20(_currency, address(this), _to, _amount);
                }
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Validates that `_addrToCheck` owns and has approved contract to transfer the appropriate amount of currency
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20(_currency).balanceOf(_addrToCheck) >= _currencyAmountToCheckAgainst &&
                IERC20(_currency).allowance(_addrToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "LazyMintERC1155: insufficient currency balance or allowance."
        );
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal returns (bool success) {
        (success, ) = to.call{ value: value }("");
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Required due to the use of `IERC20.transferFrom`.
        if (_from == address(this)) {
            IERC20(_currency).approve(address(this), _amount);
        }

        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && balAfter == balBefore + _amount, "LazyMintERC1155: failed to transfer currency.");
    }

    
    ///     =====   ERC 1155 functions  =====

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
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
        if (transfersRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "LazyMintERC1155: restricted to TRANSFER_ROLE holders.");
        }
        
        require(!paused(), "ERC1155Pausable: token transfer while paused.");

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

    ///     =====   Low level overrides  =====

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}