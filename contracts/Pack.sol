// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Tokens
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// Access Control
import "@openzeppelin/contracts/access/Ownable.sol";

// Randomness
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Protocol control center.
import { ProtocolControl } from "./ProtocolControl.sol";

contract Pack is ERC1155PresetMinterPauser, IERC1155Receiver, VRFConsumerBase, ERC2771Context, IERC2981 {
    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    /// @dev The tokenId for the next set of packs to be minted.
    uint256 public nextTokenId;

    /// @dev Chainlink VRF variables.
    uint256 public vrfFees;
    bytes32 public vrfKeyHash;

    /// @dev Pack sale royalties -- see EIP 2981
    uint256 public royaltyBps;

    /// @dev Collection level metadata.
    string public _contractURI;

    /// @dev The state of packs with a unique tokenId.
    struct PackState {
        string uri;
        address creator;
        uint256 currentSupply;
        uint256 openStart;
        uint256 openEnd;
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

    /// @dev pack tokenId => The state of packs with id `tokenId`.
    mapping(uint256 => PackState) public packs;

    /// @dev pack tokenId => rewards in pack with id `tokenId`.
    mapping(uint256 => Rewards) public rewards;

    /// @dev Chainlink VRF requestId => Chainlink VRF request state with id `requestId`.
    mapping(bytes32 => RandomnessRequest) public randomnessRequests;

    /// @dev pack tokenId => pack opener => Chainlink VRF request ID if there is an incomplete pack opening process.
    mapping(uint256 => mapping(address => bytes32)) public currentRequestId;

    /// @dev Emitted when a set of packs is created.
    event PackCreated(
        uint256 indexed packId,
        address indexed rewardContract,
        address indexed creator,
        PackState packState,
        Rewards rewards
    );
    /// @dev Emitted on a request to open a pack.
    event PackOpenRequest(uint256 indexed packId, address indexed opener, bytes32 requestId);
    /// @dev Emitted when a request to open a pack is fulfilled.
    event PackOpenFulfilled(
        uint256 indexed packId,
        address indexed opener,
        bytes32 requestId,
        address indexed rewardContract,
        uint256[] rewardIds
    );

    /// @dev Emitted when royalties for pack sales are updated.
    event RoyaltyUpdated(uint256 royaltyBps);

    /// @dev Checks whether the protocol is paused.
    modifier onlyUnpausedProtocol() {
        require(!controlCenter.systemPaused(), "Pack: The protocol is paused.");
        _;
    }

    /// @dev Checks whether the protocol is paused.
    modifier onlyProtocolAdmin() {
        require(
            controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), _msgSender()),
            "Pack: only a protocol admin can call this function."
        );
        _;
    }

    constructor(
        address payable _controlCenter,
        string memory _uri,
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fees,
        address _trustedForwarder
    ) ERC1155PresetMinterPauser(_uri) VRFConsumerBase(_vrfCoordinator, _linkToken) ERC2771Context(_trustedForwarder) {
        // Set the protocol control center.
        controlCenter = ProtocolControl(_controlCenter);

        // Set Chainlink vars.
        vrfKeyHash = _keyHash;
        vrfFees = _fees;

        // Set contract URI
        _contractURI = _uri;
    }

    /**
     *   ERC 1155 and ERC 1155 Receiver functions.
     **/

    function uri(uint256 _id) public view override returns (string memory) {
        return packs[_id].uri;
    }

    function tokenURI(uint256 _id) public view returns (string memory) {
        return packs[_id].uri;
    }


    /**
     *   External functions.
     **/

    /// @dev Lets a pack owner request to open a single pack.
    function openPack(uint256 _packId) external onlyUnpausedProtocol {
        // Check whether this call is made within the window to open packs.
        PackState memory packState = packs[_packId];
        require(
            block.timestamp >= packState.openStart && block.timestamp <= packState.openEnd,
            "Pack: the window to open packs has not started or closed."
        );

        require(LINK.balanceOf(address(this)) >= vrfFees, "Pack: Not enough LINK to fulfill randomness request.");
        require(balanceOf(_msgSender(), _packId) > 0, "Pack: sender owns no packs of the given packId.");
        require(currentRequestId[_packId][_msgSender()] == "", "Pack: must wait for the pending pack to be opened.");

        // Burn the pack being opened.
        _burn(_msgSender(), _packId, 1);

        // Send random number request.
        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFees);

        // Update state to reflect the Chainlink VRF request.
        randomnessRequests[requestId] = RandomnessRequest({ packId: _packId, opener: _msgSender() });
        currentRequestId[_packId][_msgSender()] = requestId;

        emit PackOpenRequest(_packId, _msgSender(), requestId);
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
        IERC1155(rewardsInPack.source).safeBatchTransferFrom(address(this), receiver, rewardIds, rewardAmounts, "");

        emit PackOpenFulfilled(packId, receiver, _requestId, rewardsInPack.source, rewardIds);
    }

    /// @dev Lets a protocol admin change the Chainlink VRF fee.
    function setChainlinkFees(uint256 _newFees) external onlyProtocolAdmin {
        vrfFees = _newFees;
    }

    /// @dev Lets a protocol admin transfer LINK from the contract.
    function transferLink(address _to, uint256 _amount) external onlyProtocolAdmin {
        bool success = LINK.transfer(_to, _amount);
        require(success, "Pack: Failed to transfer LINK.");
    }

    /// @dev Lets a protocol admin update the royalties paid on pack sales.
    function setRoyaltyBps(uint256 _royaltyBps) external onlyProtocolAdmin {
        require(_royaltyBps < controlCenter.MAX_BPS(), "Pack: Bps provided must be less than 10,000");

        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Sets contract URI for the storefront-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return 0; // this.onERC1155Received.selector;
    }

    /// @dev Creates pack on receiving ERC 1155 reward tokens
    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) external override onlyUnpausedProtocol returns (bytes4) {
        // Get parameters for creating packs.
        (
            string memory packURI,
            uint256 secondsUntilOpenStart,
            uint256 secondsUntilOpenEnd,
            uint256 rewardsPerOpen
        ) = abi.decode(_data, (string, uint256, uint256, uint256));

        // Create packs.
        createPack(
            _from,
            packURI,
            _msgSender(),
            _ids,
            _values,
            secondsUntilOpenStart,
            secondsUntilOpenEnd,
            rewardsPerOpen
        );

        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
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
        uint256 _secondsUntilOpenEnd,
        uint256 _rewardsPerOpen
    ) internal onlyUnpausedProtocol {
        require(hasRole(MINTER_ROLE, _creator), "Pack: only creators with MINTER_ROLE can create packs.");
        require(
            IERC1155(_rewardContract).supportsInterface(type(IERC1155).interfaceId),
            "Pack: reward contract does not implement ERC 1155."
        );

        uint256 sumOfRewards = _sumArr(_rewardAmounts);

        require(sumOfRewards % _rewardsPerOpen == 0, "Pack: invalid number of rewards per open.");

        // Get pack tokenId and total supply.
        uint256 packId = _newPackId();
        uint256 packTotalSupply = sumOfRewards / _rewardsPerOpen;

        // Store pack state.
        PackState memory packState = PackState({
            creator: _creator,
            uri: _packURI,
            currentSupply: packTotalSupply,
            openStart: block.timestamp + _secondsUntilOpenStart,
            openEnd: _secondsUntilOpenEnd == 0 ? type(uint256).max : block.timestamp + _secondsUntilOpenEnd
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

        emit PackCreated(packId, _rewardContract, _creator, packState, rewardsInPack);
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

    /// @dev Updates a token's total supply.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Decrease total supply if tokens are being burned.
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; i += 1) {
                packs[ids[i]].currentSupply -= amounts[i];
            }
        }
    }

    /// @dev Returns and then increments `currentTokenId`
    function _newPackId() internal returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId += 1;
    }

    /// @dev Returns the sum of all elements in the array
    function _sumArr(uint256[] memory arr) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < arr.length; i += 1) {
            sum += arr[i];
        }
    }

    /**
     *   Getter functions.
     **/

    /// @dev Returns the creator of a set of packs
    function creator(uint256 _packId) external view returns (address) {
        return packs[_packId].creator;
    }

    /// @dev Returns a pack for the given pack tokenId
    function getPack(uint256 _packId) external view returns (PackState memory pack) {
        pack = packs[_packId];
    }

    /// @dev Returns the URI for the storefront-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Returns a pack with its underlying rewards
    function getPackWithRewards(uint256 _packId)
        external
        view
        returns (
            PackState memory pack,
            address source,
            uint256[] memory tokenIds,
            uint256[] memory amountsPacked
        )
    {
        pack = packs[_packId];
        source = rewards[_packId].source;
        tokenIds = rewards[_packId].tokenIds;
        amountsPacked = rewards[_packId].amountsPacked;
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = packs[tokenId].creator;
        royaltyAmount = (salePrice * royaltyBps) / controlCenter.MAX_BPS();
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
