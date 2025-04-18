// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract LiquidityLocker {
    address public token;
    address public dao;

    struct Lock {
        address locker;
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;
    mapping(address => bool) public hasLocked;
    uint256 public totalLocked;

    event TokensLocked(address indexed locker, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed locker, uint256 amount);
    event LockDeleted(address indexed locker, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    constructor(address _token, address _dao) {
        require(_token != address(0), "Invalid token");
        require(_dao != address(0), "Invalid DAO");
        token = _token;
        dao = _dao;
    }

    function lockLiquidity(address from, uint256 amount, address dex, uint256 unlockTime) external onlyDAO {
        require(amount > 0, "Zero amount");
        require(unlockTime > block.timestamp + 1 days, "Unlock too soon");
        require(!hasLocked[dex], "Already locked");

        (bool success) = IERC20(token).transferFrom(from, address(this), amount);
        require(success, "Transfer failed");

        locks[dex] = Lock(from, amount, unlockTime);
        hasLocked[dex] = true;
        totalLocked += amount;

        emit TokensLocked(from, amount, unlockTime);
    }

    function release(address dex) external onlyDAO {
        Lock storage lock = locks[dex];
        require(lock.amount > 0, "Nothing locked");
        require(block.timestamp >= lock.unlockTime, "Still locked");

        uint256 amount = lock.amount;
        address to = lock.locker;

        delete locks[dex];
        delete hasLocked[dex];
        totalLocked -= amount;

        (bool success) = IERC20(token).transfer(to, amount);
        require(success, "Transfer failed");

        emit TokensUnlocked(to, amount);
        emit LockDeleted(to, amount);
    }

    function getLock(address dex) external view returns (Lock memory) {
        return locks[dex];
    }

    function isLocked(address dex) external view returns (bool) {
        return hasLocked[dex];
    }
}

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}
