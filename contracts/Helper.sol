// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRevenuePool.sol";
import "./interfaces/IGovernorVotes.sol";
import "./Governor.sol";
import "./Campaign.sol";
import "./interfaces/IRevenuePoolFactory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Helper is OwnableUpgradeable {
    constructor() {}

    struct RevenueData {
        address tokenClaim;
        uint256 claimableAmout;
        address revenuePoolAddress;
    }
    struct TokenInfoFull {
        address governorAddress;
        uint256 tokenId;
        uint256 tokenPower;
        RevenueData[] revenueDatas;
    }

    function allTokenInfo(
        Campaign campaignContract,
        address user
    ) external view {
        address[] memory investedGovernors = campaignContract
            .investedGovernorList(user);

        for (uint256 i; i < investedGovernors.length; i++) {
            IRevenuePoolFactory revenuePoolFactorys = Governor(
                investedGovernors[i]
            ).revenuePoolFactory();
            IRevenuePool[] memory pools = revenuePoolFactorys.pools();
        }
    }
}
