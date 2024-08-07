// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/IGovernorFactory.sol";
import "./Governor.sol";

contract GovernorFactory is Context, IGovernorFactory {
    ICampaign private immutable _campaign;

    uint256 public nextGovernorId;
    mapping(uint256 governorId => address) _governors;
    mapping(address governor => bool) _hasGovernor;

    uint64 public votingDelay;
    uint64 public votingPeriod;
    uint64 public timelockPeriod;
    uint64 public queuingPeriod;
    constructor(
        address campaign_,
        uint64 votingDelay_,
        uint64 votingPeriod_,
        uint64 timelockPeriod_,
        uint64 queuingPeriod_
    ) {
        _campaign = ICampaign(campaign_);

        votingDelay = votingDelay_;
        votingPeriod = votingPeriod_;
        timelockPeriod = timelockPeriod_;
        queuingPeriod = queuingPeriod_;
    }

    function createGovernor(
        string memory name,
        string memory tokenName,
        string memory tokenSymbol,
        bytes32 descriptionHash
    ) external payable returns (uint256 governorId) {
        governorId = nextGovernorId;
        nextGovernorId += 1;
        // Gover
        address governorAddress = address(
            new Governor(
                name,
                tokenName,
                tokenSymbol,
                descriptionHash,
                governorId,
                _msgSender(),
                address(_campaign),
                votingDelay,
                votingPeriod,
                timelockPeriod,
                queuingPeriod
            )
        );

        _governors[governorId] = governorAddress;
        _hasGovernor[governorAddress] = true;

        emit GovernorCreated(
            governorId,
            governorAddress,
            _msgSender(),
            descriptionHash
        );
    }

    function governor(
        uint256 governorId
    ) external view override returns (address) {
        return _governors[governorId];
    }

    function hasGovernor(
        address governorAddress
    ) external view override returns (bool) {
        return _hasGovernor[governorAddress];
    }
}
