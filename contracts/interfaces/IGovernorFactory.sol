// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernorFactory {
    event GovernorCreated(
        uint256 governorId,
        address indexed governor,
        address indexed founder,
        bytes32 indexed descriptionHash
    );

    // function createGovernor(
    //     bytes32 descriptionHash
    // ) external payable returns (uint256 governorId);

    function governor(uint256 governorId) external view returns (address);

    function hasGovernor(address governor) external view returns (bool);
}
