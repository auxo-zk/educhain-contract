// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/IGovernor.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/IRevenuePoolFactory.sol";
import "./RevenuePoolFactory.sol";
import "./GovernorVotes.sol";

contract Governor is Context, IGovernor, GovernorVotes {
    bytes32 private constant ALL_PROPOSAL_STATES_BITMAP =
        bytes32((2 ** (uint8(type(ProposalState).max) + 1)) - 1);
    string private _name;
    bytes32 private _descriptionHash;
    uint256 private _governorId;
    address private _founder;

    ICampaign private _campaign;
    IRevenuePoolFactory private _revenuePoolFactory;
    uint256 private _nextTokenId;
    uint256 private _proposalCounter;
    mapping(uint256 proposalIndex => uint256) private _proposalIds;
    mapping(uint256 proposalId => ProposalCore) private _proposals;
    mapping(uint256 proposalId => Action) private _actions;
    mapping(bytes32 operationHash => bool) private _queuedOperations;

    uint256 private _totalFunded;

    uint64 public votingDelay;
    uint64 public votingPeriod;

    uint64 public timelockPeriod;
    uint64 public queuingPeriod;

    constructor(
        string memory name_,
        string memory tokenName_,
        string memory tokenSymbol_,
        bytes32 descriptionHash_,
        uint256 governorId_,
        address founder_,
        address campaign_,
        uint64 timelockPeriod_,
        uint64 queuingPeriod_
    ) GovernorVotes(tokenName_, tokenSymbol_, campaign_) {
        _name = name_;

        _descriptionHash = descriptionHash_;

        _governorId = governorId_;
        _founder = founder_;
        _campaign = ICampaign(campaign_);

        timelockPeriod = timelockPeriod_;
        queuingPeriod = queuingPeriod_;
    }

    modifier onlyFounder() {
        require(_msgSender() == founder());
        _;
    }

    modifier onlyCampaign() {
        require(_msgSender() == address(_campaign));
        _;
    }

    function setRevenuePoolFactory(address revenuePoolFactory_) external {
        _revenuePoolFactory = IRevenuePoolFactory(revenuePoolFactory_);
    }

    function increaseFundedAndMinted(
        uint256 fundedAmount,
        uint256 mintedAmount
    ) external onlyCampaign {
        _totalFunded += fundedAmount;
        _nextTokenId += mintedAmount;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        uint64 startTime,
        uint64 votingDuration
    ) external onlyFounder returns (uint256) {
        address proposer = _msgSender();
        return
            _propose(
                targets,
                values,
                calldatas,
                descriptionHash,
                proposer,
                startTime,
                votingDuration
            );
    }

    function castVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support
    ) external returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, tokenId, voter, support);
    }

    function castVoteBatch(
        uint256 proposalId,
        uint256[] memory tokenIds,
        uint8 support
    ) external returns (uint256 totalWeight) {
        address voter = _msgSender();
        for (uint256 i; i < tokenIds.length; i++) {
            totalWeight += _castVote(proposalId, tokenIds[i], voter, support);
        }
    }

    function queue(uint256 proposalId) external {
        _validateStateBitmap(
            proposalId,
            _encodeStateBitmap(ProposalState.Succeeded)
        );
        ProposalCore storage proposal = _proposals[proposalId];
        Action storage action = _actions[proposalId];
        uint64 etaBlocks = SafeCast.toUint64(clock() + timelockPeriod);
        for (uint256 i = 0; i < action.targets.length; i++) {
            _queueOperation(
                action.targets[i],
                action.values[i],
                action.signatures[i],
                action.calldatas[i],
                proposal.descriptionHash
            );
        }
        proposal.etaBlocks = etaBlocks;
        emit ProposalQueued(proposalId, etaBlocks);
    }

    function execute(uint256 proposalId) public payable {
        _validateStateBitmap(
            proposalId,
            _encodeStateBitmap(ProposalState.Queued)
        );

        ProposalCore storage proposal = _proposals[proposalId];
        // uint256 eta = proposal.etaBlocks;
        // require(
        //     clock() >= eta && clock() <= (eta + queuingPeriod),
        //     "Governor::execute: Transaction can not be executed now."
        // );
        Action storage action = _actions[proposalId];

        for (uint256 i = 0; i < action.targets.length; i++) {
            _executeOperation(
                action.targets[i],
                action.values[i],
                action.signatures[i],
                action.calldatas[i],
                proposal.descriptionHash
            );
        }
        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external {
        _validateStateBitmap(
            proposalId,
            ALL_PROPOSAL_STATES_BITMAP ^
                _encodeStateBitmap(ProposalState.Canceled) ^
                _encodeStateBitmap(ProposalState.Expired) ^
                _encodeStateBitmap(ProposalState.Executed)
        );

        ProposalCore storage proposal = _proposals[proposalId];
        proposal.canceled = true;
        Action storage action = _actions[proposalId];

        for (uint256 i = 0; i < action.targets.length; i++) {
            _cancelOperation(
                action.targets[i],
                action.values[i],
                action.signatures[i],
                action.calldatas[i],
                proposal.descriptionHash
            );
        }

        emit ProposalCanceled(proposalId);
    }

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(targets, values, calldatas, descriptionHash)
                )
            );
    }

    function hashOperation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        bytes32 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, salt));
    }

    // ========= VIEW FUNCTIONS =========

    function clock() public view returns (uint256) {
        return block.timestamp;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function founder() public view returns (address) {
        return _founder;
    }

    function governorId() public view returns (uint256) {
        return _governorId;
    }

    function campaign() public view returns (ICampaign) {
        return _campaign;
    }

    function revenuePoolFactory() external view returns (IRevenuePoolFactory) {
        return _revenuePoolFactory;
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId;
    }

    function totalFunded() external view returns (uint256) {
        return _totalFunded;
    }

    function proposalCounter() external view returns (uint256) {
        return _proposalCounter;
    }

    function descriptionHash() external view returns (bytes32) {
        return _descriptionHash;
    }

    function proposalIds(
        uint256 proposalIndex
    ) external view returns (uint256) {
        return _proposalIds[proposalIndex];
    }

    function state(
        uint256 proposalId
    ) public view virtual returns (ProposalState) {
        // We read the struct fields into the stack at once so Solidity emits a single SLOAD
        ProposalCore storage proposal = _proposals[proposalId];
        bool proposalExecuted = proposal.executed;
        bool proposalCanceled = proposal.canceled;

        if (proposalExecuted) {
            return ProposalState.Executed;
        }

        if (proposalCanceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert GovernorNonexistentProposal(proposalId);
        }

        uint256 currentTimepoint = clock();

        if (snapshot >= currentTimepoint) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= currentTimepoint) {
            return ProposalState.Active;
        } else if (!_voteSucceeded(proposalId)) {
            return ProposalState.Defeated;
        } else if (proposalEta(proposalId) == 0) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Queued;
        }
    }

    function proposalCore(
        uint256 proposalId
    ) external view returns (ProposalCore memory) {
        return _proposals[proposalId];
    }

    function proposalSnapshot(
        uint256 proposalId
    ) public view virtual returns (uint256) {
        return _proposals[proposalId].voteStart;
    }

    function proposalDeadline(
        uint256 proposalId
    ) public view virtual returns (uint256) {
        return
            _proposals[proposalId].voteStart +
            _proposals[proposalId].voteDuration;
    }

    function proposalProposer(
        uint256 proposalId
    ) public view virtual returns (address) {
        return _proposals[proposalId].proposer;
    }

    function proposalEta(
        uint256 proposalId
    ) public view virtual returns (uint256) {
        return _proposals[proposalId].etaBlocks;
    }

    function proposalNeedsQueuing(uint256) public view virtual returns (bool) {
        return false;
    }

    // ========= INTERNAL FUNCTIONS =========
    function _propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer,
        uint64 startTime,
        uint64 votingDuration
    ) internal virtual returns (uint256 proposalId) {
        proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        if (
            targets.length != values.length ||
            targets.length != calldatas.length ||
            targets.length == 0
        ) {
            revert GovernorInvalidProposalLength(
                targets.length,
                calldatas.length,
                values.length
            );
        }
        if (_proposals[proposalId].voteStart != 0) {
            revert GovernorUnexpectedProposalState(
                proposalId,
                state(proposalId),
                bytes32(0)
            );
        }

        _proposalIds[_proposalCounter] = proposalId;
        _proposalCounter += 1;

        /// proposal
        ProposalCore storage proposal = _proposals[proposalId];
        proposal.proposer = proposer;
        proposal.voteStart = startTime;
        proposal.voteDuration = votingDuration;
        proposal.descriptionHash = descriptionHash;

        // action
        Action storage action = _actions[proposalId];
        action.targets = targets;
        action.values = values;
        action.calldatas = calldatas;

        emit ProposalCreated(
            proposalId,
            proposer,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            startTime,
            startTime + votingDuration,
            descriptionHash
        );

        // Using a named return variable to avoid stack too deep errors
    }

    function _castVote(
        uint256 proposalId,
        uint256 tokenId,
        address account,
        uint8 support
    ) internal virtual returns (uint256) {
        _validateStateBitmap(
            proposalId,
            _encodeStateBitmap(ProposalState.Active)
        );
        require(tokenId < _nextTokenId);
        uint256 weight = _getVotes(tokenId, account);
        _countVote(proposalId, tokenId, support, weight);

        emit VoteCast(account, proposalId, tokenId, support, weight);
        return weight;
    }

    function _queueOperation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        bytes32 descriptionHash
    ) internal {
        bytes32 operationHash = hashOperation(
            target,
            value,
            signature,
            data,
            descriptionHash
        );
        require(
            !_queuedOperations[operationHash],
            "Governor::_queueOperation: Operation has been queued."
        );

        _queuedOperations[operationHash] = true;
    }

    function _executeOperation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        bytes32 descriptionHash
    ) internal {
        bytes32 operationHash = hashOperation(
            target,
            value,
            signature,
            data,
            descriptionHash
        );
        require(
            _queuedOperations[operationHash],
            "Governor::_executeOperation: Operation hasn't been queued."
        );
        _queuedOperations[operationHash] = false;
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }
        // bytes memory returnData
        (bool success, ) = target.call{value: value}(callData);
        require(
            success,
            "Governor::_executeOperation: Transaction execution reverted."
        );
    }

    function _cancelOperation(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        bytes32 descriptionHash
    ) internal {
        bytes32 operationHash = hashOperation(
            target,
            value,
            signature,
            data,
            descriptionHash
        );

        _queuedOperations[operationHash] = false;
    }

    function _encodeStateBitmap(
        ProposalState proposalState
    ) internal pure returns (bytes32) {
        return bytes32(1 << uint8(proposalState));
    }

    function _validateStateBitmap(
        uint256 proposalId,
        bytes32 allowedStates
    ) private view returns (ProposalState) {
        ProposalState currentState = state(proposalId);
        if (_encodeStateBitmap(currentState) & allowedStates == bytes32(0)) {
            revert GovernorUnexpectedProposalState(
                proposalId,
                currentState,
                allowedStates
            );
        }
        return currentState;
    }
}
