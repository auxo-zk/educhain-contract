// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ICampaign {
    enum CampaignState {
        Pending,
        Active,
        Succeeded,
        Allocated
    }

    event CampaignLaunched(uint256 campaignId);

    event GovernorJoined(uint256 campaignId, uint256 governorId);

    event Fund(
        uint256 campaignId,
        uint256 governorId,
        uint256 amount,
        uint256 tokenId
    );

    event FundAllocated(uint256 campaignId, uint256[] governorIds);

    struct Course {
        address governor;
        uint256 fund;
        uint256 minted;
    }

    struct CampaignCore {
        uint256 totalFunded;
        bytes32 descriptionHash;
        uint64 fundStart;
        uint64 fundDuration;
        bool allocated;
        uint256[] governorIds;
        mapping(uint256 governorId => Course) courses;
    }

    function launchCampaign(
        bytes32 descriptionHash
    ) external returns (uint256 campaignId);

    function joinCampaign(
        uint256 governorId,
        address governor
    ) external returns (uint256);

    function fund(
        uint256 governorId
    ) external payable returns (uint256 tokenId);

    function allocateFunds() external;

    function founder() external view returns (address);

    function campaignData(
        uint256 campaignId
    )
        external
        view
        returns (
            uint256 totalFunded,
            bytes32 descriptionHash,
            uint64 fundStart,
            uint64 fundDuration,
            bool allocated,
            uint256[] memory governorIds
        );
}
