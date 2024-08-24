// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IVotes.sol";

contract ERC721Votes is ERC721, IVotes {
    error InvalidTokenOwner();

    address public _minter;
    uint256 public nextTokenId;

    mapping(uint256 tokenId => uint256) private _values;
    mapping(address user => uint256[] tokenIds) private _tokensOwned;

    constructor(
        string memory name_,
        string memory symbol_,
        address minter_
    ) ERC721(name_, symbol_) {
        _minter = minter_;
    }

    modifier onlyMinter() {
        require(_msgSender() == _minter);
        _;
    }

    function mint(
        address to,
        uint256 value
    ) external onlyMinter returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId++;
        _mint(to, tokenId);
        _values[tokenId] = value;
        _tokensOwned[to].push(tokenId);
    }

    function getVotes(
        uint256 tokenId,
        address account
    ) public view returns (uint256) {
        if (_ownerOf(tokenId) != account) {
            revert InvalidTokenOwner();
        }
        return _values[tokenId];
    }

    function getAllToken(
        address owner
    ) external view returns (TokenInfos[] memory) {
        uint256[] memory tokenOwned = _tokensOwned[owner];
        TokenInfos[] memory tokenInfos = new TokenInfos[](tokenOwned.length);
        for (uint256 i; i < tokenOwned.length; i++) {
            tokenInfos[i] = TokenInfos(tokenOwned[i], _values[i]);
        }
    }

    function getVotingPower(uint256 tokenId) external view returns (uint256) {
        return _values[tokenId];
    }
}
