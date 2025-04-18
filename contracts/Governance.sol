// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Governance {
    address public votingContract;
    address public timelockVault;
    address public liquidityLocker;
    address public admin;

    event UpdatedAddress(string component, address newAddress);
    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _votingContract, address _timelockVault, address _liquidityLocker) {
        require(_votingContract != address(0), "Invalid voting contract");
        require(_timelockVault != address(0), "Invalid timelock vault");
        require(_liquidityLocker != address(0), "Invalid liquidity locker");

        votingContract = _votingContract;
        timelockVault = _timelockVault;
        liquidityLocker = _liquidityLocker;
        admin = msg.sender;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    function setVotingContract(address _votingContract) external onlyAdmin {
        require(_votingContract != address(0), "Invalid address");
        votingContract = _votingContract;
        emit UpdatedAddress("VotingContract", _votingContract);
    }

    function setTimelockVault(address _timelockVault) external onlyAdmin {
        require(_timelockVault != address(0), "Invalid address");
        timelockVault = _timelockVault;
        emit UpdatedAddress("TimelockVault", _timelockVault);
    }

    function setLiquidityLocker(address _liquidityLocker) external onlyAdmin {
        require(_liquidityLocker != address(0), "Invalid address");
        liquidityLocker = _liquidityLocker;
        emit UpdatedAddress("LiquidityLocker", _liquidityLocker);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}
