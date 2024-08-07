// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./GovernorFactory.sol";
import "./Governor.sol";
import "./ERC721Votes.sol";
import "./interfaces/IGovernorFactory.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/IVotes.sol";

contract Campaign is Context, ICampaign {
    address public _founder;
    IGovernorFactory private immutable _governorFactory;
    uint256 public nextCampaignId;
    uint256 public currentCampaignId;
    mapping(uint256 campaignId => CampaignCore) _campaigns;

    uint64 public fundingDelay;
    uint64 public fundingPeriod;

    modifier onlyGovernorFactory() {
        require(_msgSender() == address(governorFactory()));
        _;
    }

    modifier onlyGovernor() {
        require(governorFactory().hasGovernor(_msgSender()));
        _;
    }

    modifier onlyFounder() {
        require(founder() == _msgSender());
        _;
    }

    constructor(
        uint64 fundingDelay_,
        uint64 fundingPeriod_,
        uint64 votingDelay_,
        uint64 votingPeriod_,
        uint64 timelockPeriod_,
        uint64 queuingPeriod_
    ) {
        _founder = _msgSender();
        _governorFactory = IGovernorFactory(
            address(
                new GovernorFactory(
                    address(this),
                    votingDelay_,
                    votingPeriod_,
                    timelockPeriod_,
                    queuingPeriod_
                )
            )
        );
        nextCampaignId = 1;
        fundingDelay = fundingDelay_;
        fundingPeriod = fundingPeriod_;
    }

    function launchCampaign(
        bytes32 descriptionHash
    ) external returns (uint256) {
        require(currentCampaignId == 0);
        currentCampaignId = nextCampaignId;
        nextCampaignId += 1;
        CampaignCore storage campaign = _campaigns[currentCampaignId];
        campaign.descriptionHash = descriptionHash;
        campaign.fundStart = SafeCast.toUint64(clock() + fundingDelay);
        campaign.fundDuration = fundingPeriod;

        emit CampaignLaunched(currentCampaignId);

        return currentCampaignId;
    }

    function joinCampaign(
        uint256 governorId,
        address governor
    ) external onlyGovernor returns (uint256) {
        require(state(0) == CampaignState.Pending);
        CampaignCore storage campaign = _campaigns[currentCampaignId];
        Course storage course = campaign.courses[governorId];
        require(course.governor == address(0));
        course.governor = governor;
        course.fund = 0;
        campaign.governorIds.push(governorId);

        emit GovernorJoined(currentCampaignId, governorId);

        return governorId;
    }

    function fund(
        uint256 governorId
    ) external payable returns (uint256 tokenId) {
        require(state(0) == CampaignState.Active);
        require(msg.value > 0);
        CampaignCore storage campaign = _campaigns[currentCampaignId];
        Course storage course = campaign.courses[governorId];
        require(course.governor != address(0));
        campaign.totalFunded += msg.value;
        course.fund += msg.value;
        course.minted += 1;
        Governor governor = Governor(payable(course.governor));
        IVotes erc721Votes = IVotes(governor.token());
        tokenId = erc721Votes.mint(_msgSender(), msg.value);

        emit Fund(currentCampaignId, governorId, msg.value, tokenId);
    }

    function allocateFunds() external {
        require(state(0) == CampaignState.Succeeded);

        CampaignCore storage campaign = _campaigns[currentCampaignId];
        campaign.allocated = true;

        for (uint256 i = 0; i < campaign.governorIds.length; i++) {
            uint256 governorId = campaign.governorIds[i];
            Course storage course = campaign.courses[governorId];
            bytes memory callData = new bytes(32);
            uint256 minted = course.minted;
            assembly {
                mstore(add(callData, 32), minted)
            }
            (bool success, ) = payable(course.governor).call{
                value: course.fund
            }(callData);

            require(success);
        }

        emit FundAllocated(currentCampaignId, campaign.governorIds);

        currentCampaignId = 0;
    }

    function state(uint256 campaignId) public view returns (CampaignState) {
        if (campaignId == 0) {
            require(currentCampaignId != 0);
            uint256 currentBlock = clock();
            CampaignCore storage campaign = _campaigns[currentCampaignId];
            if (campaign.allocated) {
                return CampaignState.Allocated;
            }
            if (currentBlock < campaign.fundStart) {
                return CampaignState.Pending;
            }
            if (currentBlock < campaign.fundStart + campaign.fundDuration) {
                return CampaignState.Active;
            } else {
                return CampaignState.Succeeded;
            }
        } else {
            uint256 currentBlock = clock();
            CampaignCore storage campaign = _campaigns[campaignId];
            if (campaign.allocated) {
                return CampaignState.Allocated;
            }
            if (currentBlock < campaign.fundStart) {
                return CampaignState.Pending;
            }
            if (currentBlock < campaign.fundStart + campaign.fundDuration) {
                return CampaignState.Active;
            } else {
                return CampaignState.Succeeded;
            }
        }
    }

    function clock() public view returns (uint256) {
        return block.number;
    }

    function founder() public view returns (address) {
        return _founder;
    }

    function governorFactory() public view returns (IGovernorFactory) {
        return _governorFactory;
    }

    function courseData(
        uint256 campaignId,
        uint256 governorId
    ) public view returns (Course memory) {
        require(campaignId >= 1 && campaignId < nextCampaignId);
        return _campaigns[campaignId].courses[governorId];
    }

    function campaignData(
        uint256 campaignId
    )
        public
        view
        returns (
            uint256 totalFunded,
            bytes32 descriptionHash,
            uint64 fundStart,
            uint64 fundDuration,
            bool allocated,
            uint256[] memory governorIds
        )
    {
        CampaignCore storage campaign = _campaigns[campaignId];
        totalFunded = campaign.totalFunded;
        descriptionHash = campaign.descriptionHash;
        fundStart = campaign.fundStart;
        fundDuration = campaign.fundDuration;
        allocated = campaign.allocated;
        governorIds = campaign.governorIds;
    }
}
