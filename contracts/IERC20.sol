// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IERC20
 * @dev Standard ERC20 token interface, consolidated from contracts.
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}