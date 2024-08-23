// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RevenuePoolFactory.sol";

contract RevenuePoolFactoryCreator {
    constructor() {}

    function createRevenuePoolFactory(
        address owner_,
        address governor_
    ) external returns (RevenuePoolFactory) {
        RevenuePoolFactory revenuePoolFactory = new RevenuePoolFactory(
            owner_,
            governor_
        );

        return revenuePoolFactory;
    }
}
