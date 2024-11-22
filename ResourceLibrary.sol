// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VanaResourceLibrary is AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.bytes32Set;

    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");
    uint256 public constant CURATOR_REPUTATION_THRESHOLD = 100;
    uint256 public constant DAO_PROPOSAL_THRESHOLD = 10000; // 10,000 VANA tokens

    IERC20 public vanaToken;

    Counters.Counter private _resourceCounter;
    EnumerableSet.bytes32Set private _categories;
    mapping(bytes32 => EnumerableSet.bytes32Set) private _categoryTags;

    struct ResourceMetadata {
        uint256 id;
        string title;
        string description;
        bytes32[] categories;
        bytes32[] tags;
        uint256 version;
        uint256 uploadTimestamp;
        address uploader;
    }

    struct DAOProposal {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) voted;
    }

    mapping(uint256 => ResourceMetadata) public resources;
    mapping(address => EnumerableSet.AddressSet) private _curatorsPerResource;
    mapping(uint256 => DAOProposal) public proposals;
    uint256 public proposalCounter;

    event ResourceAdded(uint256 indexed id, string title, address indexed uploader);
    event ResourceUpdated(uint256 indexed id, string title, uint256 indexed version, address indexed uploader);
    event CategoryAdded(bytes32 indexed category);
    event TagAdded(bytes32 indexed category, bytes32 indexed tag);
    event CuratorAdded(uint256 indexed resourceId, address indexed curator);
    event CuratorRemoved(uint256 indexed resourceId, address indexed curator);
    event DAOProposalCreated(uint256 indexed proposalId, string description);
    event DAOProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event DAOProposalExecuted(uint256 indexed proposalId, bool passed);

    constructor(address ipfsGateway, address _vanaToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ADMIN_ROLE, msg.sender);
        vanaToken = IERC20(_vanaToken);
    }

    // Existing functions (addResource, updateResource, addCurator, removeCurator, etc.)

    function createDAOProposal(string memory description) public {
        require(vanaToken.balanceOf(msg.sender) >= DAO_PROPOSAL_THRESHOLD, "Insufficient VANA tokens to create a proposal");
        proposalCounter++;
        proposals[proposalCounter] = DAOProposal(proposalCounter, description, 0, 0);
        emit DAOProposalCreated(proposalCounter, description);
    }

    function voteOnDAOProposal(uint256 proposalId, bool support) public {
        require(proposals[proposalId].voted[msg.sender] == false, "You have already voted on this proposal");
        proposals[proposalId].voted[msg.sender] = true;
        if (support) {
            proposals[proposalId].forVotes++;
        } else {
            proposals[proposalId].againstVotes++;
        }
        emit DAOProposalVoted(proposalId, msg.sender, support);
    }

    function executeDAOProposal(uint256 proposalId) public onlyRole(DAO_ADMIN_ROLE) {
        DAOProposal storage proposal = proposals[proposalId];
        require(proposal.forVotes > proposal.againstVotes, "Proposal did not pass");
        // Execute the proposal logic here
        // (e.g., update resource library content, structure, or management policies)
        emit DAOProposalExecuted(proposalId, true);
    }
}
