// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./GovernorFactory.sol";
import "./Governor.sol";
import "./ERC721Votes.sol";
import "./interfaces/IGovernorFactory.sol";
import "./interfaces/ICampaign.sol";
import "./interfaces/IVotes.sol";

contract Campaign is OwnableUpgradeable, ICampaign {
    IGovernorFactory public governorFactory;
    uint256 public nextCampaignId;

    mapping(address founder => uint256[] campaignIds) _campaignsOwn;
    mapping(address governorAddress => uint256[] campaignIds) _joinedCampaign;

    mapping(uint256 campaignId => CampaignCore) _campaigns;
    mapping(uint256 campaignId => address founder) public campaignFounders;

    mapping(address investor => mapping(uint256 campaignId => bool))
        public isInvestedCampaign;
    mapping(address investor => mapping(address governor => bool))
        public isInvestedGovernor;
    mapping(address investor => mapping(uint256 campaignId => mapping(address governor => bool)))
        public isInvestedGovernorInACampaign;

    mapping(address investor => uint256[] campaignId) _investedCampaignList;
    mapping(address investor => address[] governor) _investedGovernorList;
    mapping(address investor => mapping(uint256 campaignId => address[] governors)) _investedGovernorInACampaignList;

    modifier onlyGovernorFactory() {
        require(msg.sender == address(governorFactory));
        _;
    }

    modifier onlyGovernor() {
        require(governorFactory.hasGovernor(msg.sender));
        _;
    }

    function initialize(address initialOwner_) public initializer {
        require(initialOwner_ != address(0), "Invalid address");
        __Ownable_init(initialOwner_);
        nextCampaignId = 1;
    }

    function setGovernorFactory(
        IGovernorFactory _governorFactory
    ) public onlyOwner {
        require(address(_governorFactory) != address(0), "Invalid address");
        governorFactory = _governorFactory;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
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
        campaignFounders[currentCampaignId] = msg.sender;

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

        _joinedCampaign[governor].push(campaignId);

        emit GovernorJoined(campaignId, governorId);

        return governorId;
    }

    function fund(
        uint256 campaignId,
        uint256 governorId,
        uint256 amount
    ) public returns (uint256 tokenId) {
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
        tokenId = erc721Votes.mint(msg.sender, amount);

        if (!isInvestedCampaign[msg.sender][campaignId]) {
            isInvestedCampaign[msg.sender][campaignId] = true;
            _investedCampaignList[msg.sender].push(campaignId);
        }

        if (!isInvestedGovernor[msg.sender][address(governor)]) {
            isInvestedGovernor[msg.sender][address(governor)] = true;
            _investedGovernorList[msg.sender].push(address(governor));
        }

        if (
            !isInvestedGovernorInACampaign[msg.sender][campaignId][
                address(governor)
            ]
        ) {
            isInvestedGovernorInACampaign[msg.sender][campaignId][
                address(governor)
            ] = true;
            _investedGovernorInACampaignList[msg.sender][campaignId].push(
                address(governor)
            );
        }

        emit Fund(campaignId, governorId, amount, tokenId);
    }

    function funds(
        uint256 campaignId,
        uint256[] calldata governorIds,
        uint256[] calldata amounts
    ) public  {
        require(governorIds.length == amounts.length, "Invalid length");
        for(uint i; i< governorIds.length; i ++){
            fund(campaignId, governorIds[i], amounts[i]);
        }
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

    function courseData(
        uint256 campaignId,
        uint256 governorId
    ) public view returns (Course memory) {
        return _campaigns[campaignId].courses[governorId];
    }

    function campaignsOwn(
        address _owner
    ) public view returns (uint256[] memory) {
        return _campaignsOwn[_owner];
    }

    function joinedCampaign(
        address governorAddress
    ) public view returns (uint256[] memory) {
        return _joinedCampaign[governorAddress];
    }

    function investedCampaignList(
        address investor
    ) public view returns (uint256[] memory) {
        return _investedCampaignList[investor];
    }

    function investedGovernorList(
        address investor
    ) public view returns (address[] memory) {
        return _investedGovernorList[investor];
    }

    function investedGovernorInACampaignList(
        address investor,
        uint256 campaignId
    ) public view returns (address[] memory) {
        return _investedGovernorInACampaignList[investor][campaignId];
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
