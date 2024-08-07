// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IRevenuePool.sol";
import "./interfaces/IGovernor.sol";
import "./interfaces/IGovernorVotes.sol";
import "./interfaces/IRevenuePool.sol";

import "hardhat/console.sol";

contract RevenuePool is Context, IRevenuePool {
    IGovernorVotes private immutable _governor;
    uint256 private _revenue;
    uint256 private _totalFunded;
    uint256 private _nextTokenId;
    mapping(uint256 tokenId => bool) private _claimed;
    constructor(
        address governor_,
        uint256 totalFunded_,
        uint256 nextTokenId_
    ) payable {
        require(msg.value > 0);
        _governor = IGovernorVotes(governor_);
        _revenue = msg.value;
        _totalFunded = totalFunded_;
        _nextTokenId = nextTokenId_;
    }

    function claim(uint256 tokenId) external {
        if (claimed(tokenId)) {
            revert();
        }
        require(tokenId < _nextTokenId);
        uint256 value = governor().token().getVotes(tokenId, _msgSender());
        _claimed[tokenId] = true;
        uint256 claimAmount = (revenue() * value) / totalFunded();

        payable(_msgSender()).transfer(claimAmount);

        emit RevenueClaimed(_msgSender(), tokenId);
    }

    function governor() public view returns (IGovernorVotes) {
        return _governor;
    }
    function revenue() public view returns (uint256) {
        return _revenue;
    }
    function totalFunded() public view returns (uint256) {
        return _totalFunded;
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId;
    }

    function claimed(uint256 tokenId) public view returns (bool) {
        return _claimed[tokenId];
    }
}
