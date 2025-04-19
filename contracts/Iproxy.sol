// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IProxy
 * @dev Interface for proxy contract upgrades, based on ProxyAdmin.sol.
 */
interface IProxy {
    function upgradeTo(address newImplementation) external;
}