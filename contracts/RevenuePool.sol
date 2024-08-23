// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IRevenuePool.sol";
import "./interfaces/IGovernor.sol";
import "./interfaces/IGovernorVotes.sol";
import "./interfaces/IRevenuePool.sol";

contract RevenuePool is Context, IRevenuePool {
    IGovernorVotes private immutable _governor;
    address private _token;
    uint256 private _revenue;
    uint256 private _totalFunded;
    uint256 private _nextTokenId;
    mapping(uint256 tokenId => bool) private _claimed;
    constructor(
        address governor_,
        address token_,
        uint256 totalFunded_,
        uint256 nextTokenId_,
        uint256 revenue_
    ) payable {
        _governor = IGovernorVotes(governor_);
        _revenue = revenue_;
        _token = token_;
        _totalFunded = totalFunded_;
        _nextTokenId = nextTokenId_;
    }

    function claim(uint256 tokenId) external {
        require(!claimed(tokenId), "Claimed!");
        require(tokenId < _nextTokenId, "Invalid tokenId");

        uint256 value = governor().token().getVotes(tokenId, _msgSender());

        _claimed[tokenId] = true;

        uint256 claimAmount = (_revenue * value) / _totalFunded;

        ERC20(_token).transfer(_msgSender(), claimAmount);

        emit RevenueClaimed(_msgSender(), tokenId);
    }

    function claimable(uint256 tokenId) public view returns (uint256) {
        if (tokenId < _nextTokenId || !_claimed[tokenId]) {
            uint256 value = governor().token().getVotes(tokenId, _msgSender());
            return (_revenue * value) / _totalFunded;
        }
        return 0;
    }

    function claimables(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory claimableAmounts = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            claimableAmounts[i] = claimable(tokenIds[i]);
        }
    }

    function token() public view returns (address) {
        return _token;
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
