// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IGovernor.sol";
import "./interfaces/IRevenuePool.sol";
import "./interfaces/IRevenuePoolFactory.sol";
import "./RevenuePool.sol";

contract RevenuePoolFactory is Context, IRevenuePoolFactory {
    address private _owner;
    IGovernor private immutable _governor;
    IRevenuePool[] private _pools;

    constructor(address owner_, address governor_) {
        _owner = owner_;
        _governor = IGovernor(governor_);
    }

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }
    function createPool() external payable onlyOwner {
        require(msg.value > 0);
        RevenuePool revenuePool = new RevenuePool{value: msg.value}(
            address(_governor),
            _governor.totalFunded(),
            _governor.nextTokenId()
        );
        _pools.push(IRevenuePool(address(revenuePool)));

        emit PoolCreated(address(revenuePool));
    }

    function pool(uint256 poolIndex) public view returns (IRevenuePool) {
        return _pools[poolIndex];
    }

    function poolCounter() external view returns (uint256) {
        return _pools.length;
    }
}
