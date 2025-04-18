// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TimelockVault {
    address public governanceContract;
    address public token;
    uint256 public lockDuration;
    mapping(address => uint256) public lockedTokens;
    mapping(address => uint256) public unlockTime;

    event TokensLocked(address indexed user, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed user, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == governanceContract, "Not DAO");
        _;
    }

    modifier onlyAfterUnlockTime(address _user) {
        require(block.timestamp >= unlockTime[_user], "Tokens are still locked");
        _;
    }

    constructor(address _governanceContract, address _token, uint256 _lockDuration) {
        require(_governanceContract != address(0), "Invalid governance address");
        require(_token != address(0), "Invalid token address");

        governanceContract = _governanceContract;
        token = _token;
        lockDuration = _lockDuration;
    }

    function lockTokens(address _user, uint256 _amount) external onlyDAO {
        require(_user != address(0), "Invalid user address");
        require(_amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transferFrom(_user, address(this), _amount), "Transfer failed");

        lockedTokens[_user] += _amount;
        unlockTime[_user] = block.timestamp + lockDuration;

        emit TokensLocked(_user, _amount, unlockTime[_user]);
    }

    function unlockTokens(address _user) external onlyDAO onlyAfterUnlockTime(_user) {
        uint256 amount = lockedTokens[_user];
        require(amount > 0, "No tokens to unlock");

        lockedTokens[_user] = 0;
        unlockTime[_user] = 0;

        require(IERC20(token).transfer(_user, amount), "Transfer failed");

        emit TokensUnlocked(_user, amount);
    }

    function updateLockDuration(uint256 _newLockDuration) external onlyDAO {
        require(_newLockDuration > 0, "Duration must be positive");
        lockDuration = _newLockDuration;
    }
}
