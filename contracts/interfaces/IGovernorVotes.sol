// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVotes.sol";
interface IGovernorVotes {
    enum VoteType {
        Against,
        For,
        Abstain
    }

    error GovernorAlreadyCastVote(uint256 tokenId);

    error GovernorInvalidVoteType();

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(uint256 tokenId => bool) hasVoted;
    }

    function hasVoted(
        uint256 proposalId,
        uint256 tokenId
    ) external view returns (bool);

    function proposalVotes(
        uint256 proposalId
    )
        external
        view
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);

    function token() external view returns (IVotes);
}
