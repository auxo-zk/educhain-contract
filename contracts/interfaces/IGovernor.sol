// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICampaign.sol";
import "./IRevenuePoolFactory.sol";
interface IGovernor {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    error GovernorInvalidProposalLength(
        uint256 targets,
        uint256 calldatas,
        uint256 values
    );

    error GovernorUnexpectedProposalState(
        uint256 proposalId,
        ProposalState current,
        bytes32 expectedStates
    );

    error GovernorDisabledDeposit();

    error GovernorOnlyProposer(address account);

    error GovernorOnlyExecutor(address account);

    error GovernorNonexistentProposal(uint256 proposalId);

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        bytes32 descriptionHash
    );

    event ProposalQueued(uint256 proposalId, uint256 etaBlocks);

    event ProposalExecuted(uint256 proposalId);

    event ProposalCanceled(uint256 proposalId);

    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 weight
    );

    struct ProposalCore {
        address proposer;
        uint64 voteStart;
        uint64 voteDuration;
        bytes32 descriptionHash;
        bool executed;
        bool canceled;
        uint64 etaBlocks;
    }

    struct Action {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external returns (uint256 proposalId);

    function castVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support
    ) external returns (uint256 weight);

    function castVoteBatch(
        uint256 proposalId,
        uint256[] memory tokenIds,
        uint8 support
    ) external returns (uint256 totalWeight);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

    function cancel(uint256 proposalId) external;

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external pure returns (uint256);

    function hashOperation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        bytes32 salt
    ) external pure returns (bytes32);

    // ========= VIEW FUNCTIONS =========

    function name() external view returns (string memory);

    function governorId() external view returns (uint256);

    function campaign() external view returns (ICampaign);

    function revenuePoolFactory() external view returns (IRevenuePoolFactory);

    function nextTokenId() external view returns (uint256);

    function totalFunded() external view returns (uint256);

    function proposalCounter() external view returns (uint256);

    function proposalIds(uint256 proposalIndex) external view returns (uint256);

    function state(uint256 proposalId) external view returns (ProposalState);

    function proposalCore(
        uint256 proposalId
    ) external view returns (ProposalCore memory);

    function proposalDeadline(
        uint256 proposalId
    ) external view returns (uint256);

    function proposalProposer(
        uint256 proposalId
    ) external view returns (address);

    function proposalEta(uint256 proposalId) external view returns (uint256);

    function proposalNeedsQueuing(
        uint256 proposalId
    ) external view returns (bool);
}
