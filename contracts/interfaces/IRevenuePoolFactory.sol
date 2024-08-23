// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRevenuePool.sol";
interface IRevenuePoolFactory {
    event PoolCreated(address pool);

    function createPool(address token, uint256 amount) external payable;

    function pool(uint256 poolIndex) external view returns (IRevenuePool);

    function pools() external view returns (IRevenuePool[] memory);

    function poolCounter() external view returns (uint256);
}
