// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IVotes.sol";

contract ERC721Votes is ERC721, IVotes {
    error InvalidTokenOwner();

    address public _minter;
    uint256 public nextTokenId;
    mapping(uint256 tokenId => uint256) private _values;

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

    function getVotingPower(uint256 tokenId) external view returns (uint256) {
        return _values[tokenId];
    }
}
