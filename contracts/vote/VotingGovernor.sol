// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { GovernorUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import { GovernorSettingsUpgradeable } from  "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import { GovernorCountingSimpleUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import { GovernorVotesUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import { GovernorVotesQuorumFractionUpgradeable } from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import { ERC2771ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { ERC1155HolderUpgradeable, ERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC20VotesUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

// Helper interfaces
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Upgradeability
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VotingGovernor is
    Initializable,
    ERC2771ContextUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable
{
    string public contractURI;
    uint256 public proposalIndex;

    struct Proposal {
        uint256 proposalId;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        string description;
    }

    /// @dev proposal index => Proposal
    mapping(uint256 => Proposal) public proposals;

    /// @dev proposal ID => proposal index
    mapping(uint256 => uint256) public indexForProposal;

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        string memory _name,
        ERC20VotesUpgradeable _token,
        uint256 _initialVotingDelay,
        uint256 _initialVotingPeriod,
        uint256 _initialProposalThreshold,
        uint256 _initialVoteQuorumFraction,
        address _trustedForwarder,
        string memory _uri
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.        
        __ERC2771Context_init(_trustedForwarder);
        __ERC721Holder_init();
        __ERC1155Holder_init();
        __Governor_init(_name);
        __GovernorSettings_init(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(_initialVoteQuorumFraction);

        // Initialize this contract's state.
        contractURI = _uri;
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256 proposalId) {
        proposalId = super.propose(targets, values, calldatas, description);

        proposals[proposalIndex] = Proposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            targets: targets,
            values: values,
            signatures: new string[](targets.length),
            calldatas: calldatas,
            startBlock: proposalSnapshot(proposalId),
            endBlock: proposalDeadline(proposalId),
            description: description
        });

        proposalIndex += 1;
    }

    /// @dev Returns all proposals made.
    function getAllProposals() external view returns (Proposal[] memory allProposals) {
        uint256 nextProposalIndex = proposalIndex;

        allProposals = new Proposal[](nextProposalIndex);
        for (uint256 i = 0; i < nextProposalIndex; i += 1) {
            allProposals[i] = proposals[i];
        }
    }

    function setContractURI(string calldata uri) external onlyGovernance {
        contractURI = uri;
    }

    function proposalThreshold() public view override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return GovernorSettingsUpgradeable.proposalThreshold();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155ReceiverUpgradeable, GovernorUpgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _msgSender() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}
