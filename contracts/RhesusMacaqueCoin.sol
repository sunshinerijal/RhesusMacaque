// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title RHEMToken
 * @dev Fully hardcoded ERC20 token with snapshot, capped supply, burn, DAO governance, and Merkle airdrop
 */
contract RhesusMacaqueCoin {
    string public constant name = "Rhesus Macaque Coin";
    string public constant symbol = "RHEM";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    uint256 public constant CAP = 1_000_000_000 * 10**18;

    address public timelock;
    address public communityWallet;
    address public dao;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Snapshot Voting
    mapping(address => mapping(uint256 => uint256)) private _snapshots;
    mapping(address => uint256) private _currentSnapshotId;
    uint256 private _snapshotCounter;

    // Merkle Airdrop
    bytes32 public merkleRoot;
    mapping(address => bool) public airdropClaimed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Snapshot(uint256 id);
    event TokensBurned(uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    constructor(address _dao, address _communityWallet, address _timelock, bytes32 _merkleRoot) {
        require(_dao != address(0) && _communityWallet != address(0) && _timelock != address(0), "Zero address");
        dao = _dao;
        communityWallet = _communityWallet;
        timelock = _timelock;
        merkleRoot = _merkleRoot;

        // Mint 1 Billion RHEM tokens
        uint256 full = CAP;
        _mint(timelock, (full * 15) / 100);            // 15% to timelock for LP
        _mint(communityWallet, (full * 15) / 100);     // 15% to community wallet
        _mint(address(this), (full * 40) / 100);       // 40% staking, rewards, airdrop
        _mint(dao, (full * 10) / 100);                 // 10% to DAO
        _mint(msg.sender, (full * 20) / 100);          // 20% deployer for initial liquidity

        require(_totalSupply == CAP, "Incorrect mint");
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function snapshot() public onlyDAO returns (uint256) {
        _snapshotCounter++;
        emit Snapshot(_snapshotCounter);
        return _snapshotCounter;
    }

    function getPastVotes(address account, uint256 snapshotId) external view returns (uint256) {
        return _snapshots[account][snapshotId];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Allowance too low");
        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        require(_totalSupply + amount <= CAP, "Cap exceeded");
        _totalSupply += amount;
        _balances[to] += amount;
        _updateSnapshot(to);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(_balances[from] >= amount, "Insufficient balance");
        _balances[from] -= amount;
        _totalSupply -= amount;
        _updateSnapshot(from);
        emit Transfer(from, address(0), amount);
        emit TokensBurned(amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "Insufficient");
        require(to != address(0), "Zero address");

        uint256 burnFee = (amount * 5) / 1000;           // 0.5%
        uint256 devFee = (amount * 25) / 10000;          // 0.25%
        uint256 finalAmount = amount - burnFee - devFee;

        _balances[from] -= amount;
        _balances[to] += finalAmount;
        _balances[communityWallet] += devFee;
        _totalSupply -= burnFee;

        _updateSnapshot(from);
        _updateSnapshot(to);
        _updateSnapshot(communityWallet);

        emit Transfer(from, to, finalAmount);
        emit Transfer(from, communityWallet, devFee);
        emit Transfer(from, address(0), burnFee);
        emit TokensBurned(burnFee);
    }

    function _updateSnapshot(address user) internal {
        _snapshots[user][_snapshotCounter] = _balances[user];
        _currentSnapshotId[user] = _snapshotCounter;
    }

    // Burn token externally (optional)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // Claim airdrop via Merkle proof
    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external {
        require(!airdropClaimed[msg.sender], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(verify(proof, leaf), "Invalid proof");
        airdropClaimed[msg.sender] = true;
        _transfer(address(this), msg.sender, amount);
    }

    function verify(bytes32[] calldata proof, bytes32 leaf) public view returns (bool) {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 element = proof[i];
            if (hash <= element) hash = keccak256(abi.encodePacked(hash, element));
            else hash = keccak256(abi.encodePacked(element, hash));
        }
        return hash == merkleRoot;
    }
}
