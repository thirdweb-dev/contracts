// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Base
import "./openzeppelin-presets/ERC1155PresetUpgradeable.sol";
import "./interfaces/IThirdwebContract.sol";
import "./interfaces/IThirdwebOwnable.sol";
import "./interfaces/IThirdwebRoyalty.sol";

// Randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Meta transactions
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/FeeType.sol";

// Helper interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

// Thirdweb top-level
import "./interfaces/ITWFee.sol";

contract Pack is
    Initializable,
    IThirdwebContract,
    IThirdwebOwnable,
    IThirdwebRoyalty,
    VRFConsumerBase,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC1155PresetUpgradeable
{
    bytes32 private constant MODULE_TYPE = bytes32("Pack");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The thirdweb contract with fee related information.
    ITWFee public immutable thirdwebFee;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The token Id of the next token to be minted.
    uint256 public nextTokenId;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint256 private royaltyBps;

    /// @dev Collection level metadata.
    string public contractURI;

    /// @dev Chainlink VRF variables.
    uint256 private vrfFees;
    bytes32 private vrfKeyHash;

    /// @dev The state of packs with a unique tokenId.
    struct PackState {
        string uri;
        address creator;
        uint256 openStart;
    }

    /// @dev The rewards in a given set of packs with a unique tokenId.
    struct Rewards {
        address source;
        uint256[] tokenIds;
        uint256[] amountsPacked;
        uint256 rewardsPerOpen;
    }

    /// @dev The state of a random number request made to Chainlink VRF on opening a pack.
    struct RandomnessRequest {
        uint256 packId;
        address opener;
    }

    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => RoyaltyInfo) private royaltyInfoForToken;

    /// @dev pack tokenId => The state of packs with id `tokenId`.
    mapping(uint256 => PackState) public packs;

    /// @dev pack tokenId => rewards in pack with id `tokenId`.
    mapping(uint256 => Rewards) public rewards;

    /// @dev Chainlink VRF requestId => Chainlink VRF request state with id `requestId`.
    mapping(bytes32 => RandomnessRequest) public randomnessRequests;

    /// @dev pack tokenId => pack opener => Chainlink VRF request ID if there is an incomplete pack opening process.
    mapping(uint256 => mapping(address => bytes32)) public currentRequestId;

    /// @dev Emitted when a set of packs is created.
    event PackAdded(
        uint256 indexed packId,
        address indexed rewardContract,
        address indexed creator,
        uint256 packTotalSupply,
        PackState packState,
        Rewards rewards
    );

    /// @dev Emitted on a request to open a pack.
    event PackOpenRequested(uint256 indexed packId, address indexed opener, bytes32 requestId);

    /// @dev Emitted when a request to open a pack is fulfilled.
    event PackOpenFulfilled(
        uint256 indexed packId,
        address indexed opener,
        bytes32 requestId,
        address indexed rewardContract,
        uint256[] rewardIds
    );

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address prevOwner, address newOwner);

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
        address[] memory _trustedForwarders,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _fees,
        bytes32 _keyHash
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC2771Context_init(_trustedForwarders);
        __ERC1155Preset_init(_defaultAdmin, _contractURI);

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
     * @dev See {ERC1155-_mint}.
     */
    function mint(
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override {
        revert("cannot freely mint more packs");
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function mintBatch(
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override {
        revert("cannot freely mint more packs");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert("Must use batch transfer.");
    }

    /// @dev Creates pack on receiving ERC 1155 reward tokens
    function onERC1155BatchReceived(
        address _operator,
        address,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) public override whenNotPaused returns (bytes4) {
        // Get parameters for creating packs.
        (string memory packURI, uint256 secondsUntilOpenStart, uint256 rewardsPerOpen) = abi.decode(
            _data,
            (string, uint256, uint256)
        );

        // Create packs.
        createPack(_operator, packURI, _msgSender(), _ids, _values, secondsUntilOpenStart, rewardsPerOpen);

        return this.onERC1155BatchReceived.selector;
    }

    /**
     *   External functions.
     **/

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

    /// @dev Lets a pack owner request to open a single pack.
    function openPack(uint256 _packId) external whenNotPaused {
        PackState memory packState = packs[_packId];

        require(block.timestamp >= packState.openStart, "outside window to open packs.");
        require(LINK.balanceOf(address(this)) >= vrfFees, "out of LINK.");
        require(balanceOf(_msgSender(), _packId) > 0, "must own packs to open.");
        require(currentRequestId[_packId][_msgSender()] == "", "must wait for the pending pack to open.");

        // Burn the pack being opened.
        _burn(_msgSender(), _packId, 1);

        // Send random number request.
        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFees);

        // Update state to reflect the Chainlink VRF request.
        randomnessRequests[requestId] = RandomnessRequest({ packId: _packId, opener: _msgSender() });
        currentRequestId[_packId][_msgSender()] = requestId;

        emit PackOpenRequested(_packId, _msgSender(), requestId);
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
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
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

    /// @dev Creates packs with rewards.
    function createPack(
        address _creator,
        string memory _packURI,
        address _rewardContract,
        uint256[] memory _rewardIds,
        uint256[] memory _rewardAmounts,
        uint256 _secondsUntilOpenStart,
        uint256 _rewardsPerOpen
    ) internal whenNotPaused {
        require(
            IERC1155Upgradeable(_rewardContract).supportsInterface(type(IERC1155Upgradeable).interfaceId),
            "Pack: reward contract does not implement ERC 1155."
        );
        require(hasRole(MINTER_ROLE, _creator), "not minter.");
        require(_rewardIds.length > 0, "must add at least one reward.");

        uint256 sumOfRewards = _sumArr(_rewardAmounts);

        require(sumOfRewards % _rewardsPerOpen == 0, "invalid number of rewards per open.");

        // Get pack tokenId and total supply.
        uint256 packId = nextTokenId;
        nextTokenId += 1;

        uint256 packTotalSupply = sumOfRewards / _rewardsPerOpen;

        // Store pack state.
        PackState memory packState = PackState({
            creator: _creator,
            uri: _packURI,
            openStart: block.timestamp + _secondsUntilOpenStart
        });

        // Store reward state.
        Rewards memory rewardsInPack = Rewards({
            source: _rewardContract,
            tokenIds: _rewardIds,
            amountsPacked: _rewardAmounts,
            rewardsPerOpen: _rewardsPerOpen
        });

        packs[packId] = packState;
        rewards[packId] = rewardsInPack;

        // Mint packs to creator.
        _mint(_creator, packId, packTotalSupply, "");

        emit PackAdded(packId, _rewardContract, _creator, packTotalSupply, packState, rewardsInPack);
    }

    /// @dev Returns a reward tokenId using `_randomness` provided by RNG.
    function getReward(
        uint256 _packId,
        uint256 _randomness,
        Rewards memory _rewardsInPack
    ) internal returns (uint256[] memory rewardTokenIds, uint256[] memory rewardAmounts) {
        uint256 base = _sumArr(_rewardsInPack.amountsPacked);
        uint256 step;
        uint256 prob;

        rewardTokenIds = new uint256[](_rewardsInPack.rewardsPerOpen);
        rewardAmounts = new uint256[](_rewardsInPack.rewardsPerOpen);

        for (uint256 j = 0; j < _rewardsInPack.rewardsPerOpen; j += 1) {
            prob = uint256(keccak256(abi.encode(_randomness, j))) % base;

            for (uint256 i = 0; i < _rewardsInPack.tokenIds.length; i += 1) {
                if (prob < (_rewardsInPack.amountsPacked[i] + step)) {
                    // Store the reward's tokenId
                    rewardTokenIds[j] = _rewardsInPack.tokenIds[i];
                    rewardAmounts[j] = 1;

                    // Update amount of reward available in pack.
                    _rewardsInPack.amountsPacked[i] -= 1;

                    // Reset step
                    step = 0;
                    break;
                } else {
                    step += _rewardsInPack.amountsPacked[i];
                }
            }
        }

        rewards[_packId] = _rewardsInPack;
    }

    /// @dev Called by Chainlink VRF with a random number, completing the opening of a pack.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        RandomnessRequest memory request = randomnessRequests[_requestId];

        uint256 packId = request.packId;
        address receiver = request.opener;

        // Pending request completed
        delete currentRequestId[packId][receiver];

        // Get tokenId of the reward to distribute.
        Rewards memory rewardsInPack = rewards[packId];

        (uint256[] memory rewardIds, uint256[] memory rewardAmounts) = getReward(packId, _randomness, rewardsInPack);

        // Distribute the reward to the pack opener.
        IERC1155Upgradeable(rewardsInPack.source).safeBatchTransferFrom(
            address(this),
            receiver,
            rewardIds,
            rewardAmounts,
            ""
        );

        emit PackOpenFulfilled(packId, receiver, _requestId, rewardsInPack.source, rewardIds);
    }

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

    /// @dev Returns the sum of all elements in the array
    function _sumArr(uint256[] memory arr) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < arr.length; i += 1) {
            sum += arr[i];
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
        override(ERC1155PresetUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /// @dev See EIP 1155
    function uri(uint256 _id) public view override returns (string memory) {
        return packs[_id].uri;
    }

    /// @dev Returns a pack with its underlying rewards
    function getPackWithRewards(uint256 _packId)
        external
        view
        returns (
            PackState memory pack,
            uint256 packTotalSupply,
            address source,
            uint256[] memory tokenIds,
            uint256[] memory amountsPacked
        )
    {
        pack = packs[_packId];
        packTotalSupply = totalSupply(_packId);
        source = rewards[_packId].source;
        tokenIds = rewards[_packId].tokenIds;
        amountsPacked = rewards[_packId].amountsPacked;
    }
}
