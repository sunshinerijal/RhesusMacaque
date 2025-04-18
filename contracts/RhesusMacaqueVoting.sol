// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract RhesusMacaqueVoting {
    address public governanceContract;
    address public token;
    uint256 public votingDuration;
    uint256 public proposalCount;
    mapping(address => uint256) public balances;
    mapping(uint256 => Proposal) public proposals;

    struct Proposal {
        address proposer;
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool executed;
        mapping(address => bool) voted;
        uint256 votesFor;
        uint256 votesAgainst;
        string description;
    }

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    modifier onlyDAO() {
        require(msg.sender == governanceContract, "Not DAO");
        _;
    }

    constructor(address _governanceContract, address _token, uint256 _votingDuration) {
        require(_governanceContract != address(0), "Invalid governance address");
        require(_token != address(0), "Invalid token address");

        governanceContract = _governanceContract;
        token = _token;
        votingDuration = _votingDuration;
    }

    function createProposal(string memory _description) external onlyDAO returns (uint256) {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposer = msg.sender;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingDuration;
        newProposal.description = _description;

        emit ProposalCreated(proposalCount, msg.sender, _description);

        return proposalCount;
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting closed");
        require(!proposal.voted[msg.sender], "Already voted");

        uint256 voterBalance = balances[msg.sender];
        require(voterBalance > 0, "No voting power");

        if (_support) {
            proposal.votesFor += voterBalance;
        } else {
            proposal.votesAgainst += voterBalance;
        }

        proposal.voted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting not yet ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
            // Execute the proposal logic here, e.g., timelock execution
        }
    }

    function updateVotingPower(address _user, uint256 _amount) external onlyDAO {
        require(_user != address(0), "Invalid address");
        balances[_user] = _amount;
    }
}
