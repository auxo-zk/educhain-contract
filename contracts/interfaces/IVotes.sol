// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotes {
    struct TokenInfos {
        uint256 id;
        uint256 campaignId;
        uint256 value;
    }

    function getVotes(
        uint256 tokenId,
        address account
    ) external view returns (uint256);

    function mint(
        address to,
        uint256 value,
        uint256 campaignId
    ) external returns (uint256);

    function getVotingPower(uint256 tokenId) external view returns (uint256);

    function tokensOwned(
        address _owner
    ) external view returns (uint256[] memory);

    function getAllToken(
        address owner
    ) external view returns (TokenInfos[] memory);
}
