// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Corrected imports from OpenZeppelin's stable v4.9.3 version
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.3/contracts/token/ERC20/IERC20Upgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.3/contracts/access/Ownable2StepUpgradeable.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts-upgradeable/v4.9.3/contracts/proxy/utils/Initializable.sol";

contract CrossChainBridge is Initializable, Ownable2StepUpgradeable {
    address public token;
    address public wormholeRouter;
    address public governanceContract;

    event TokensBridged(address indexed user, uint256 amount, uint64 destinationChain);

    modifier onlyDAO() {
        require(msg.sender == governanceContract, "Only DAO can call");
        _;
    }

    function initialize(address _token, address _wormholeRouter, address _governance) public initializer {
        require(_token != address(0), "Invalid token address");
        require(_governance != address(0), "Invalid governance address");
        __Ownable2Step_init();
        token = _token;
        wormholeRouter = _wormholeRouter;
        governanceContract = _governance;
        _transferOwnership(governanceContract);
    }

    function bridgeTokens(address user, uint256 amount, uint64 destinationChain) external onlyDAO {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20Upgradeable(token).transferFrom(user, address(this), amount), "Transfer failed");
        emit TokensBridged(user, amount, destinationChain);
    }
}
