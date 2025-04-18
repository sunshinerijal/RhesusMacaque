// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

// OpenZeppelin upgradeable contracts (v4.9.5)
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/access/Ownable2StepUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/security/ReentrancyGuardUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.5/contracts/token/ERC20/IERC20Upgradeable.sol";

contract RHEMSwap is Initializable, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    address public token;
    address public governanceContract;
    address public poolToken;
    uint256 public liquidity;

    event LiquidityAdded(address indexed user, uint256 amount);
    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    modifier onlyDAO() {
        require(msg.sender == governanceContract, "Only DAO can call");
        _;
    }

    function initialize(
        address _token,
        address _governance,
        address _poolToken
    ) public initializer {
        require(_token != address(0), "Invalid token address");
        require(_governance != address(0), "Invalid governance address");
        require(_poolToken != address(0), "Invalid pool token address");

        __Ownable2Step_init();
        __ReentrancyGuard_init();

        token = _token;
        governanceContract = _governance;
        poolToken = _poolToken;

        _transferOwnership(governanceContract);
    }

    function addLiquidity(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        bool success = IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        liquidity += amount;

        emit LiquidityAdded(msg.sender, amount);
    }

    function swap(uint256 amountIn) external nonReentrant {
        require(amountIn > 0, "Amount must be greater than 0");

        bool sentIn = IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amountIn);
        require(sentIn, "Token transfer failed");

        uint256 amountOut = (amountIn * 99) / 100;

        bool sentOut = IERC20Upgradeable(poolToken).transfer(msg.sender, amountOut);
        require(sentOut, "Pool token transfer failed");

        emit Swapped(msg.sender, amountIn, amountOut);
    }
}
