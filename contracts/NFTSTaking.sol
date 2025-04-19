// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


// Fully embedded ERC721 minimal interface
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal RHEM ERC20 interface
interface IRHEMToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract NFTStaking {
    address public dao;
    address public nftAddress;
    address public rhemToken;

    uint256 public rewardRatePerSecond; // Example: 1e16 = 0.01 RHEM per second
    uint256 public minimumStakeDuration;

    struct StakeInfo {
        address staker;
        uint256 tokenId;
        uint256 startTime;
        bool active;
    }

    mapping(uint256 => StakeInfo) public stakes; // tokenId => stake info
    mapping(address => uint256[]) public userStakes; // user => tokenIds

    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event MinimumDurationUpdated(uint256 duration);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    constructor(
        address _nftAddress,
        address _rhemToken,
        address _dao,
        uint256 _rewardRatePerSecond,
        uint256 _minimumStakeDuration
    ) {
        require(_nftAddress != address(0), "Invalid NFT");
        require(_rhemToken != address(0), "Invalid token");
        require(_dao != address(0), "Invalid DAO");
        nftAddress = _nftAddress;
        rhemToken = _rhemToken;
        dao = _dao;
        rewardRatePerSecond = _rewardRatePerSecond;
        minimumStakeDuration = _minimumStakeDuration;
    }

    function stake(uint256 tokenId) external {
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not NFT owner");

        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        stakes[tokenId] = StakeInfo({
            staker: msg.sender,
            tokenId: tokenId,
            startTime: block.timestamp,
            active: true
        });

        userStakes[msg.sender].push(tokenId);
        emit Staked(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external {
        StakeInfo storage stakeData = stakes[tokenId];
        require(stakeData.active, "Not staked");
        require(stakeData.staker == msg.sender, "Not staker");
        require(block.timestamp >= stakeData.startTime + minimumStakeDuration, "Stake still locked");

        uint256 stakingDuration = block.timestamp - stakeData.startTime;
        uint256 reward = stakingDuration * rewardRatePerSecond;

        stakeData.active = false;

        require(IRHEMToken(rhemToken).transfer(msg.sender, reward), "Reward transfer failed");
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        emit Unstaked(msg.sender, tokenId, reward);
    }

    function getStakedTokens(address user) external view returns (uint256[] memory) {
        return userStakes[user];
    }

    function updateRewardRate(uint256 newRate) external onlyDAO {
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    function updateMinimumDuration(uint256 duration) external onlyDAO {
        minimumStakeDuration = duration;
        emit MinimumDurationUpdated(duration);
    }

    function isTokenStaked(uint256 tokenId) external view returns (bool) {
        return stakes[tokenId].active;
    }

    function pendingReward(uint256 tokenId) external view returns (uint256) {
        StakeInfo memory stakeData = stakes[tokenId];
        if (!stakeData.active) return 0;
        return (block.timestamp - stakeData.startTime) * rewardRatePerSecond;
    }
}
