// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Base
import "./interfaces/IPack.sol";
// import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

// Randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Meta transactions
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

// Lib
import "./lib/MultiTokenTransferLib.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/FeeType.sol";

// Helper interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

// Thirdweb top-level
import "./interfaces/ITWFee.sol";

// TODO: need to add pausability and burnability.

contract Pack is
    Initializable,
    IPack,
    VRFConsumerBase,
    AccessControlEnumerableUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155Upgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Pack");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev The thirdweb contract with fee related information.
    ITWFee public immutable thirdwebFee;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The token Id of the next token to be minted.
    uint256 public nextTokenId;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint128 private royaltyBps;

    /// @dev Max bps in the thirdweb system
    uint128 private constant MAX_BPS = 10_000;

    /// @dev Collection level metadata.
    string public contractURI;

    /// @dev Chainlink VRF variables.
    uint256 private vrfFees;
    bytes32 private vrfKeyHash;

    /// @dev The state of a random number request made to Chainlink VRF on opening a pack.
    struct RandomnessRequest {
        uint256 packId;
        address opener;
    }

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /// @dev pack tokenId => The state of packs with id `tokenId`.
    mapping(uint256 => PackState) public packInfo;

    /// @dev Chainlink VRF requestId => Chainlink VRF request state with id `requestId`.
    // mapping(bytes32 => RandomnessRequest) public randomnessRequests;

    /// @dev pack tokenId => pack opener => Chainlink VRF request ID if there is an incomplete pack opening process.
    // mapping(uint256 => mapping(address => bytes32)) public currentRequestId;

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        address _thirdwebFee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) initializer {
        thirdwebFee = ITWFee(_thirdwebFee);
    }

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _trustedForwarder,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _fees,
        bytes32 _keyHash
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarder);
        __ERC1155_init(_contractURI);

        // Initialize this contract's state.
        vrfKeyHash = _keyHash;
        vrfFees = _fees;

        name = _name;
        symbol = _symbol;
        royaltyRecipient = _royaltyRecipient;
        royaltyBps = _royaltyBps;
        contractURI = _contractURI;

        _owner = _defaultAdmin;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    /**
     *      Public functions
     */

    /// @dev Returns the module type of the contract.
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

    /**
     *   External functions.
     **/
    

    // TODO: add requisite modifiers to function.
    function createPack(
        MultiTokenTransferLib.MultiToken calldata _tokensToPack,
        TokensPerOpen calldata _tokensPerOpen,
        string calldata _uri,
        uint256 _openStartTimestamp
    ) 
        external
        returns (uint256 packId, uint256 packAmount)
    {
        // Validate inputs
        verifyPackInfo(_tokensToPack, _tokensPerOpen);

        // Get pack Id
        packId = nextTokenId;
        nextTokenId += 1;

        // Get amount of packs to mint
        packAmount = getPackAmount(_tokensToPack, _tokensPerOpen);

        // Store pack state
        packInfo[packId] = PackState({
            uri: _uri,
            openStartTimestamp: _openStartTimestamp,
            tokensPerOpen: _tokensPerOpen,
            tokensPacked: _tokensToPack
        });

        MultiTokenTransferLib.transferAll(_msgSender(), address(this), _tokensToPack);

        _mint(_msgSender(), packId, packAmount, "");

        // TODO: emit event
    }

    function verifyPackInfo(
        MultiTokenTransferLib.MultiToken calldata _tokensToPack,
        TokensPerOpen calldata _tokensPerOpen
    )
        internal
    {
        bool isValidData = _tokensToPack.erc1155AmountsToWrap.length == _tokensPerOpen.erc1155TokensPerOpen.length;
        if(isValidData) {
            for(uint256 i = 0; i < _tokensToPack.erc1155AmountsToWrap.length; i += 1) {
                isValidData = _tokensToPack.erc1155AmountsToWrap[i].length == _tokensPerOpen.erc1155TokensPerOpen[i].length;

                if(!isValidData) {
                    break;
                }
            }
        }
        require(isValidData, "incorrect ERC1155 token info");

        require(
            _tokensToPack.erc20AmountsToWrap.length == _tokensPerOpen.erc20TokensPerOpen.length,
            "incorrect ERC20 token info"
        );
    }

    function getPackAmount(
        MultiTokenTransferLib.MultiToken calldata _tokensToPack,
        TokensPerOpen calldata _tokensPerOpen
    )
        internal
        returns (uint256 packAmount)
    {
        for(uint256 i = 0; i < _tokensToPack.erc721TokensToWrap.length; i += 1) {
            packAmount += _tokensToPack.erc721TokensToWrap[i].length;
        }

        for(uint256 i = 0; i < _tokensToPack.erc1155TokensToWrap.length; i += 1) {
            for(uint256 j = 0; j < _tokensToPack.erc1155AmountsToWrap[i].length; j += 1) {
                packAmount += _tokensToPack.erc1155AmountsToWrap[i][j] % _tokensPerOpen.erc1155TokensPerOpen[i][j];
            }
        }

        for(uint256 i = 0; i < _tokensToPack.erc20AmountsToWrap.length; i += 1) {
            packAmount += _tokensToPack.erc20AmountsToWrap[i] % _tokensPerOpen.erc20TokensPerOpen[i];
        }
    }

    // TODO: add requisite modifiers to function.
    function openPack(uint256 _packId, uint256 _amountToOpen, address _receiver) external {

        require(_packId < nextTokenId, "pack does not exist");
        require(balanceOf(_msgSender(), _packId) >= _amountToOpen, "insufficient pack balance");

        // TODO: write getRandomNumbers
        uint256[] memory randomNumbers = getRandomNumbers(_amountToOpen);

        // TODO: write getTokensFromPack
        MultiTokenTransferLib.MultiToken memory tokensToTransfer = getTokensFromPack(_packId, _amountToOpen);

        _burn(_msgSender(), _packId, _amountToOpen);

        MultiTokenTransferLib.transferAll(address(this), _receiver, tokensToTransfer);
    }

    function getRandomNumbers(uint256 _quantityOfNumbersToReturn) internal returns (uint256[] memory randomNumbers) {
        
        randomNumbers = new uint256[](_quantityOfNumbersToReturn);
        uint256 randomNumber = blockhash(block.number - 1);

        for (uint256 i = 0; i < _quantityOfNumbersToReturn; i++) {
            randomNumbers[i] = uint256(keccak256(abi.encode(randomNumber, i)));
        }
    }

    function getTokensFromPack(
        uint256 _packId,
        uint256 _amountToOpen
    ) 
        internal
        returns (MultiTokenTransferLib.MultiToken memory tokensToTranfer)
    {
        
    }

    /// @dev See EIP-2981
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

    /// @dev Lets a module admin withdraw link from the contract.
    function withdrawLink(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool success = LINK.transfer(_to, _amount);
        require(success, "failed to withdraw LINK.");
    }

    /// @dev Returns the platform fee bps and recipient.
    function getDefaultRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId) public view returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     *      External: setter functions
     */

    /// @dev Lets a module admin change the Chainlink VRF fee.
    function setChainlinkFees(uint256 _newFees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vrfFees = _newFees;
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        // address _prevOwner = _owner;
        _owner = _newOwner;

        // emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_royaltyBps <= MAX_BPS, "exceed royalty bps");

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_bps <= MAX_BPS, "exceed royalty bps");

        royaltyInfoForToken[_tokenId] = RoyaltyInfo({ recipient: _recipient, bps: _bps });

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    /**
     *   Internal functions.
     **/

    // /// @dev Called by Chainlink VRF with a random number, completing the opening of a pack.
    // function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    //     RandomnessRequest memory request = randomnessRequests[_requestId];

    //     uint256 packId = request.packId;
    //     address receiver = request.opener;

    //     // Pending request completed
    //     delete currentRequestId[packId][receiver];

    //     // Get tokenId of the reward to distribute.
    //     Rewards memory rewardsInPack = rewards[packId];

    //     (uint256[] memory rewardIds, uint256[] memory rewardAmounts) = getReward(packId, _randomness, rewardsInPack);

    //     // Distribute the reward to the pack opener.
    //     IERC1155Upgradeable(rewardsInPack.source).safeBatchTransferFrom(
    //         address(this),
    //         receiver,
    //         rewardIds,
    //         rewardAmounts,
    //         ""
    //     );

    //     emit PackOpenFulfilled(packId, receiver, _requestId, rewardsInPack.source, rewardIds);
    // }

    /// @dev Runs on every transfer.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(
                hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to),
                "transfers restricted to TRANSFER_ROLE holders"
            );
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

    /**
     *   Rest: view functions
     **/

    /// @dev See EIP 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, IERC165Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev See EIP 1155
    function uri(uint256 _id) public view override returns (string memory) {
        return packInfo[_id].uri;
    }
}
