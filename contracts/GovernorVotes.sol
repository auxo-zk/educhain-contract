// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVotes.sol";
import "./interfaces/IGovernorVotes.sol";
import "./ERC721Votes.sol";

contract GovernorVotes is IGovernorVotes {
    IVotes private immutable _token;
    mapping(uint256 proposalId => ProposalVote) private _proposalVotes;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        address minter_
    ) {
        _token = IVotes(
            address(new ERC721Votes(tokenName_, tokenSymbol_, minter_))
        );
    }

    function hasVoted(
        uint256 proposalId,
        uint256 tokenId
    ) public view returns (bool) {
        return _proposalVotes[proposalId].hasVoted[tokenId];
    }

    function proposalVotes(
        uint256 proposalId
    )
        public
        view
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes)
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (
            proposalVote.againstVotes,
            proposalVote.forVotes,
            proposalVote.abstainVotes
        );
    }

    function token() public view virtual returns (IVotes) {
        return _token;
    }

    // ======== INTERNAL FUNCTIONS ========

    function _countVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 totalWeight
    ) internal returns (uint256) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        if (proposalVote.hasVoted[tokenId]) {
            revert GovernorAlreadyCastVote(tokenId);
        }
        proposalVote.hasVoted[tokenId] = true;
        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += totalWeight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += totalWeight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += totalWeight;
        } else {
            revert GovernorInvalidVoteType();
        }

        return totalWeight;
    }

    function _voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    function _getVotes(
        uint256 tokenId,
        address account
    ) internal view returns (uint256) {
        return token().getVotes(tokenId, account);
    }
}
