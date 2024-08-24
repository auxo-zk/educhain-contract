// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRevenuePool.sol";
import "./interfaces/IGovernorVotes.sol";
import "./Governor.sol";
import "./Campaign.sol";
import "./interfaces/IRevenuePoolFactory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Helper is OwnableUpgradeable {
    address public campaignContract;

    mapping(address governor => mapping(uint256 tokenId => uint256 amount))
        public claimedAmounts;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner_,
        address campaignContract_
    ) public initializer {
        require(initialOwner_ != address(0), "Invalid address");
        require(campaignContract_ != address(0), "Invalid address");

        __Ownable_init(initialOwner_);

        campaignContract = campaignContract_;
    }

    function setCampaignAddress(address _campaignContract) external onlyOwner {
        require(_campaignContract != address(0), "Invalid address");
        campaignContract = _campaignContract;
    }

    function claimable(
        address governorAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 totalAmount;

        IRevenuePoolFactory revenuePoolFactorys = Governor(governorAddress)
            .revenuePoolFactory();

        IRevenuePool[] memory pools = revenuePoolFactorys.pools();

        for (uint256 j; j < pools.length; j++) {
            totalAmount += pools[j].claimable(tokenId);
        }

        return totalAmount;
    }

    function claimables(
        address governorAddress,
        uint256[] calldata tokenIds
    )
        public
        view
        returns (uint256[] memory claimables, uint256[] memory claimeds)
    {
        uint256[] memory claimables = new uint256[](tokenIds.length);
        uint256[] memory claimeds = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            claimables[i] = claimable(governorAddress, tokenIds[i]);
            claimeds[i] = claimedAmounts[governorAddress][tokenIds[i]];
        }

        return (claimables, claimeds);
    }

    function claim(address governorAddress, uint256 tokenId) external {
        IRevenuePoolFactory revenuePoolFactorys = Governor(governorAddress)
            .revenuePoolFactory();

        IRevenuePool[] memory pools = revenuePoolFactorys.pools();

        for (uint256 j; j < pools.length; j++) {
            uint256 claimAmount = pools[j].claimable(tokenId);
            if (claimAmount > 0) {
                address tokenAddress = pools[j].token();
                pools[j].claim(tokenId);

                claimedAmounts[governorAddress][tokenId] += claimAmount;
            }
        }
    }
}
