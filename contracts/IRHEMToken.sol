// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IRHEMToken
 * @dev Minimal interface for RHEM token interactions, based on NFTStaking.sol.
 */
interface IRHEMToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}