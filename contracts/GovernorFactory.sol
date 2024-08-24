// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICampaign.sol";
import "./interfaces/IGovernorFactory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Governor.sol";
import "./RevenuePoolFactoryCreator.sol";
import "./interfaces/IVotes.sol";

contract GovernorFactory is OwnableUpgradeable, IGovernorFactory {
    ICampaign private _campaign;
    RevenuePoolFactoryCreator _revenuePoolFactoryCreator;

    uint256 public nextGovernorId;
    mapping(uint256 governorId => address) _governors;
    mapping(address governor => bool) _hasGovernor;
    mapping(address founder => uint256[]) _founderGovernorIds;

    uint64 public votingDelay;
    uint64 public votingPeriod;
    uint64 public timelockPeriod;
    uint64 public queuingPeriod;

    function initialize(
        address initialOwner_,
        address campaign_,
        address revenuePoolFactoryCreator_,
        uint64 timelockPeriod_,
        uint64 queuingPeriod_
    ) public initializer {
        require(initialOwner_ != address(0), "Invalid address");
        require(campaign_ != address(0), "Invalid address");
        require(revenuePoolFactoryCreator_ != address(0), "Invalid address");

        __Ownable_init(initialOwner_);

        _campaign = ICampaign(campaign_);
        timelockPeriod = timelockPeriod_;
        queuingPeriod = queuingPeriod_;
        _revenuePoolFactoryCreator = RevenuePoolFactoryCreator(
            revenuePoolFactoryCreator_
        );
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

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
                msg.sender,
                address(_campaign),
                timelockPeriod,
                queuingPeriod
            )
        );

        RevenuePoolFactory revenuePoolFactory = _revenuePoolFactoryCreator
            .createRevenuePoolFactory(msg.sender, governorAddress);

        Governor(governorAddress).setRevenuePoolFactory(
            address(revenuePoolFactory)
        );

        _governors[governorId] = governorAddress;
        _hasGovernor[governorAddress] = true;
        _founderGovernorIds[msg.sender].push(governorId);

        emit GovernorCreated(
            governorId,
            governorAddress,
            msg.sender,
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

    function lastProposal(
        address governorAddress
    ) external view returns (Governor.ProposalCore memory, uint256 proposalId) {
        uint256 counter = Governor(governorAddress).proposalCounter();
        if (counter > 0) {
            uint256 proposalId = Governor(governorAddress).proposalIds(
                counter - 1
            );
            return (
                Governor(governorAddress).proposalCore(proposalId),
                proposalId
            );
        }
    }

    function getAllToken(
        address governorAddress,
        address tokenOwner
    ) external view returns (IVotes.TokenInfos[] memory, uint256 totalValue) {
        IVotes.TokenInfos[] memory tokenInfos = IVotes(
            Governor(governorAddress).token()
        ).getAllToken(tokenOwner);

        for (uint256 i; i < tokenInfos.length; i++) {
            totalValue += tokenInfos[i].value;
        }
        return (tokenInfos, totalValue);
    }
}
