/**
        IGNORE THIS CONTRACT FOR NOW. THIS IS JUST FOR REFERENCE.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// Access control + Security
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";


contract LazyMintERC1155 is ERC1155, Pausable, ERC2771Context, AccessControlEnumerable, ReentrancyGuard {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 public nextTokenIdToMint;

    /// @dev The next token ID of the already NFT that can be claimed.
    uint256 public nextTokenIdToClaim;

    struct MintCondition {
        uint256 startTimestamp;
        uint256 maxMintSupply;
        uint256 currentMintSupply;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeSecondsLimitPerTransaction;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
    }

    struct PublicMintConditions {
        uint256 nextConditionIndex;

        mapping(uint256 => MintCondition) mintConditionAtIndex;
        mapping(uint256 => uint256) nextValidTimestampForClaim;
    }

    mapping(uint256 => string) public altURI;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => PublicMintConditions) public mintConditions;
    
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "only minter");
        _;
    }

    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only module admin");
        _;
    }

    constructor(
        string memory _baseURI,
        address _trustedForwarder
    ) 
        ERC1155(_baseURI)
        ERC2771Context(_trustedForwarder)
    {}

    ///     =====   Public functions  =====

    function getLastStartedMintConditionIndex() public view returns (uint256) {

        uint256 nextConditionIndex = mintConditions.nextConditionIndex;

        require(nextConditionIndex > 0, "no public mint condition");

        for (uint256 i = nextConditionIndex; i > 0; i -= 1) {
            if (block.timestamp >= mintConditions.mintConditionAtIndex[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("no active mint condition");
    }

    ///     =====   External functions  =====

    function assignURIs(string[] calldata _uris) external onlyMinter {
                
        uint256 id = nextTokenIdToMint;
        for (uint256 i = 0; i < _uris.length; i++) {
            altURI[id] = _uris[i];
            id += 1;
        }

        nextTokenIdToMint = id;
        // TODO: emit event.
    }

    function lazyMint(uint256 _amount) external onlyMinter {
        nextTokenIdToMint += _amount;
        // TODO: emit event.
    }

    function claim(uint256 _tokenId, uint256 quantity, bytes32[] calldata proofs) external payable nonReentrant {
        
        // Get the claim conditions.        

        // Verify claim validity. If not valid, revert.      

        // If there's a price, collect price.       

        // Mint the relevant tokens to claimer.
        
        // Emit event.
    }

    function setPublicMintConditions(MintCondition[] calldata conditions) external onlyModuleAdmin {

        // make sure the conditions are sorted in ascending order
        uint256 lastConditionStartTimestamp = 0;

        for (uint256 i = 0; i < conditions.length; i++) {
            // the input of startTimestamp is the number of seconds from now.
            if (lastConditionStartTimestamp != 0) {
                require(
                    lastConditionStartTimestamp < conditions[i].startTimestamp,
                    "startTimestamp must be in ascending order"
                );
            }
            require(conditions[i].maxMintSupply > 0, "max mint supply cannot be 0");
            require(conditions[i].quantityLimitPerTransaction > 0, "quantity limit cannot be 0");

            mintConditions.mintConditionAtIndex[i] = MintCondition({
                startTimestamp: block.timestamp + conditions[i].startTimestamp,
                maxMintSupply: conditions[i].maxMintSupply,
                currentMintSupply: 0,
                quantityLimitPerTransaction: conditions[i].quantityLimitPerTransaction,
                waitTimeSecondsLimitPerTransaction: conditions[i].waitTimeSecondsLimitPerTransaction,
                pricePerToken: conditions[i].pricePerToken,
                currency: conditions[i].currency,
                merkleRoot: conditions[i].merkleRoot
            });


            lastConditionStartTimestamp = conditions[i].startTimestamp;
        }

        // TODO: emit event.
    }

    
    ///     =====   ERC 1155 functions  =====

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            totalSupply[ids[i]] -= amounts[i];
        }
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
        
        require(!paused(), "ERC1155Pausable: token transfer while paused");

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

    ///     ===== Low level overrides   =====

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}