// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./GovToken.sol";

contract DAO {
    GovToken public govToken; // The GovToken contract is imported and used here. declaring a state variable named govToken of type GovToken. Stores the address

    enum VoteType { None, Yes, No } // user defined type, represents named list of possible constant values. Essentially 3 possible states for the type VoteType

    struct Proposal { // create a custom structure / struct called Proposal, which stores info about the proposal
        string description;
        uint256 yesCount;
        uint256 noCount;
        uint256 deadline;
        bool executed; 
        mapping(address => VoteType) votes; // mapping is within the proposal struct, to dtermine if the voter has voted and what the vote was
    }

    Proposal[] public proposals;

    uint256 public constant VOTING_DURATION = 3 days;

    constructor(address _govToken) {
        govToken = GovToken(_govToken);
    }

    /// @notice Create a new proposal with a text description
    function createProposal(string calldata _description) external {
        Proposal storage p = proposals.push();
        p.description = _description;
        p.deadline = block.timestamp + VOTING_DURATION;
    }

    /// @notice Vote on a proposal
    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp < p.deadline, "Voting closed");

        VoteType prevVote = p.votes[msg.sender];
        require(prevVote == VoteType.None, "Already voted");

        uint256 weight = govToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            p.yesCount += weight;
            p.votes[msg.sender] = VoteType.Yes;
        } else {
            p.noCount += weight;
            p.votes[msg.sender] = VoteType.No;
        }
    }

    /// @notice Get status of a proposal
    function getProposalStatus(uint256 proposalId) public view returns (string memory) {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp < p.deadline) {
            return "Voting in progress";
        }

        if (p.yesCount > p.noCount) {
            return "Passed";
        } else if (p.noCount > p.yesCount) {
            return "Failed";
        } else {
            return "Tied";
        }
    }

    /// @notice Get total number of proposals
    function getProposalCount() public view returns (uint256) {
        return proposals.length;
    }
}