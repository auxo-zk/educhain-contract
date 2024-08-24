// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernorVotes.sol";

interface IRevenuePool {
    event RevenueClaimed(address account, uint256 tokenId);

    function governor() external view returns (IGovernorVotes);

    function revenue() external view returns (uint256);

    function totalFunded() external view returns (uint256);

    function nextTokenId() external view returns (uint256);

    function claimed(uint256 tokenId) external view returns (bool);

    function claimable(uint256 tokenId) external view returns (uint256);

    function claimables(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory);

    function token() external view returns (address);

    function claim(uint256 tokenId) external;
}
