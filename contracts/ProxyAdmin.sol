// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IProxy {
    function upgradeTo(address newImplementation) external;
}

contract ProxyAdmin {
    address public dao;

    constructor(address _dao) {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    function upgrade(address proxy, address newImplementation) external onlyDAO {
        require(proxy != address(0), "Invalid proxy address");
        IProxy(proxy).upgradeTo(newImplementation);
    }
}
