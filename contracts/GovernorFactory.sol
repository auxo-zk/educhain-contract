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
    mapping(address founder => uint256[]) _founderGovernorIds;

    uint64 public votingDelay;
    uint64 public votingPeriod;
    uint64 public timelockPeriod;
    uint64 public queuingPeriod;
    constructor(
        address campaign_,
        uint64 timelockPeriod_,
        uint64 queuingPeriod_
    ) {
        _campaign = ICampaign(campaign_);
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
                timelockPeriod,
                queuingPeriod
            )
        );

        _governors[governorId] = governorAddress;
        _hasGovernor[governorAddress] = true;
        _founderGovernorIds[_msgSender()].push(governorId);

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

    function founderGovernorIds(
        address founder
    ) external view returns (uint256[] memory) {
        return _founderGovernorIds[founder];
    }

    function founderGovernorAddresses(
        address founder
    ) external view returns (address[] memory) {
        uint256 arrayLength = _founderGovernorIds[founder].length;

        address[] memory addresses = new address[](arrayLength);

        for (uint256 i; i < arrayLength; i++) {
            addresses[i] = _governors[_founderGovernorIds[founder][i]];
        }

        return addresses;
    }

    function hasGovernor(
        address governorAddress
    ) external view override returns (bool) {
        return _hasGovernor[governorAddress];
    }
}
