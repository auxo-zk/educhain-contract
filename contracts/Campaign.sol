// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./GovernorFactory.sol";
import "./Governor.sol";
import "./ERC721Votes.sol";
import "./interfaces/IGovernorFactory.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/IVotes.sol";

contract Campaign is Context, ICampaign {
    IGovernorFactory private immutable _governorFactory;
    uint256 public nextCampaignId;
    mapping(uint256 campaignId => CampaignCore) _campaigns;
    mapping(address => uint256[]) _campaignsOwn;

    modifier onlyGovernorFactory() {
        require(_msgSender() == address(governorFactory()));
        _;
    }

    modifier onlyGovernor() {
        require(governorFactory().hasGovernor(_msgSender()));
        _;
    }

    constructor(uint64 timelockPeriod_, uint64 queuingPeriod_) {
        _governorFactory = IGovernorFactory(
            address(
                new GovernorFactory(
                    address(this),
                    timelockPeriod_,
                    queuingPeriod_
                )
            )
        );
        nextCampaignId = 1;
    }

    function launchCampaign(
        uint64 startFunding,
        uint64 duration,
        address tokenRaising,
        bytes32 descriptionHash
    ) external returns (uint256) {
        uint256 currentCampaignId = nextCampaignId;
        nextCampaignId += 1;
        CampaignCore storage campaign = _campaigns[currentCampaignId];
        campaign.descriptionHash = descriptionHash;
        campaign.fundStart = startFunding;
        campaign.fundDuration = duration;
        campaign.tokenRaising = tokenRaising;

        _campaignsOwn[msg.sender].push(currentCampaignId);

        emit CampaignLaunched(currentCampaignId);

        return currentCampaignId;
    }

    function joinCampaign(
        uint256 campaignId,
        address governor,
        bytes32 descriptionHash
    ) external returns (uint256) {
        uint256 governorId = Governor(governor).governorId();
        address founder = Governor(governor).founder();
        require(founder == msg.sender, "Not founder");

        require(state(campaignId) == CampaignState.Pending);

        CampaignCore storage campaign = _campaigns[campaignId];
        Course storage course = campaign.courses[governorId];
        require(course.governor == address(0));
        course.governor = governor;
        course.descriptionHash = descriptionHash;

        campaign.governorIds.push(governorId);

        emit GovernorJoined(campaignId, governorId);

        return governorId;
    }

    function fund(
        uint256 campaignId,
        uint256 governorId,
        uint256 amount
    ) external payable returns (uint256 tokenId) {
        require(state(campaignId) == CampaignState.Active);

        CampaignCore storage campaign = _campaigns[campaignId];
        Course storage course = campaign.courses[governorId];
        require(course.governor != address(0));

        // transfer money to this contract
        ERC20(campaign.tokenRaising).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        campaign.totalFunded += amount;
        course.fund += amount;
        course.minted += 1;
        Governor governor = Governor(payable(course.governor));
        IVotes erc721Votes = IVotes(governor.token());
        tokenId = erc721Votes.mint(_msgSender(), amount);

        emit Fund(campaignId, governorId, amount, tokenId);
    }

    function allocateFunds(uint256 campaignId) external {
        require(state(campaignId) == CampaignState.Succeeded);

        CampaignCore storage campaign = _campaigns[campaignId];
        campaign.allocated = true;
        ERC20 tokenRaising = ERC20(campaign.tokenRaising);

        for (uint256 i = 0; i < campaign.governorIds.length; i++) {
            uint256 governorId = campaign.governorIds[i];

            Course storage course = campaign.courses[governorId];

            tokenRaising.transfer(course.governor, course.fund);

            Governor(course.governor).increaseFundedAndMinted(
                course.fund,
                course.minted
            );
        }

        emit FundAllocated(campaignId, campaign.governorIds);
    }

    function state(uint256 campaignId) public view returns (CampaignState) {
        uint256 currentTimeStamp = block.timestamp;
        CampaignCore storage campaign = _campaigns[campaignId];
        if (campaign.allocated) {
            return CampaignState.Allocated;
        }
        if (currentTimeStamp < campaign.fundStart) {
            return CampaignState.Pending;
        }
        if (currentTimeStamp < campaign.fundStart + campaign.fundDuration) {
            return CampaignState.Active;
        } else {
            return CampaignState.Succeeded;
        }
    }

    function governorFactory() public view returns (IGovernorFactory) {
        return _governorFactory;
    }

    function courseData(
        uint256 campaignId,
        uint256 governorId
    ) public view returns (Course memory) {
        return _campaigns[campaignId].courses[governorId];
    }

    function campaignsOwn(
        address owner
    ) public view returns (uint256[] memory) {
        return _campaignsOwn[owner];
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
            address tokenRaising,
            uint256[] memory governorIds
        )
    {
        CampaignCore storage campaign = _campaigns[campaignId];
        totalFunded = campaign.totalFunded;
        descriptionHash = campaign.descriptionHash;
        fundStart = campaign.fundStart;
        fundDuration = campaign.fundDuration;
        allocated = campaign.allocated;
        tokenRaising = campaign.tokenRaising;
        governorIds = campaign.governorIds;
    }
}
