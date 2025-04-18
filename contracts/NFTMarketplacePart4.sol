// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NFTMarketplacePart4 {
    address public dao;
    address public devWallet;
    address public burnAddress;
    IERC20 public rhemToken;

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public ownedNFTs;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => bool) public stakedNFTs;
    mapping(address => uint256[]) public userStakes;

    uint256 public listingFee;
    uint256 public saleFee;

    struct NFT {
        address owner;
        string tokenURI;
        bool listed;
    }

    struct Listing {
        uint256 price;
        address owner;
        bool listed;
    }

    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);
    event Minted(address indexed owner, uint256 tokenId, string tokenURI);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTListed(address indexed owner, uint256 tokenId, uint256 price);
    event NFTUnlisted(uint256 tokenId);
    event NFTSold(address indexed buyer, uint256 tokenId, uint256 price);
    event ListingFeeUpdated(uint256 newFee);
    event SaleFeeUpdated(uint256 newFee);

    modifier onlyDAO() {
        require(msg.sender == dao, "Not authorized");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(nfts[tokenId].owner == msg.sender, "Not the owner");
        _;
    }

    function initializeMarketplace(
        address _dao,
        address _devWallet,
        address _rhemToken,
        address _burnAddress
    ) public {
        require(dao == address(0), "Already initialized");
        require(_dao != address(0), "Invalid DAO");
        require(_devWallet != address(0), "Invalid dev wallet");
        require(_rhemToken != address(0), "Invalid RHEM token");

        dao = _dao;
        devWallet = _devWallet;
        rhemToken = IERC20(_rhemToken);
        burnAddress = _burnAddress;
    }

    function stakeNFT(uint256 tokenId) external {
        require(nfts[tokenId].owner == msg.sender, "Not owner");
        require(!stakedNFTs[tokenId], "Already staked");

        stakedNFTs[tokenId] = true;
        userStakes[msg.sender].push(tokenId);

        emit NFTStaked(msg.sender, tokenId);
    }

    function unstakeNFT(uint256 tokenId) external {
        require(nfts[tokenId].owner == msg.sender, "Not owner");
        require(stakedNFTs[tokenId], "Not staked");

        stakedNFTs[tokenId] = false;
        _removeUserStake(msg.sender, tokenId);

        emit NFTUnstaked(msg.sender, tokenId);
    }

    function _removeUserStake(address user, uint256 tokenId) internal {
        uint256[] storage stakes = userStakes[user];
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i] == tokenId) {
                stakes[i] = stakes[stakes.length - 1];
                stakes.pop();
                break;
            }
        }
    }

    function setListingFee(uint256 _fee) external onlyDAO {
        listingFee = _fee;
        emit ListingFeeUpdated(_fee);
    }

    function setSaleFee(uint256 _fee) external onlyDAO {
        saleFee = _fee;
        emit SaleFeeUpdated(_fee);
    }

    function listNFT(uint256 tokenId, uint256 price) external onlyOwnerOf(tokenId) {
        require(!nfts[tokenId].listed, "Already listed");
        require(price > 0, "Price must be > 0");

        listings[tokenId] = Listing(price, msg.sender, true);
        nfts[tokenId].listed = true;

        emit NFTListed(msg.sender, tokenId, price);
    }

    function unlistNFT(uint256 tokenId) external onlyOwnerOf(tokenId) {
        require(listings[tokenId].listed, "Not listed");

        listings[tokenId].listed = false;
        nfts[tokenId].listed = false;

        emit NFTUnlisted(tokenId);
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.listed, "Not listed");

        uint256 price = listing.price;
        uint256 burnAmount = (price * 50) / 10000;    // 0.5%
        uint256 devAmount = (price * 25) / 10000;     // 0.25%
        uint256 sellerAmount = price - burnAmount - devAmount;

        require(rhemToken.transferFrom(msg.sender, address(this), price), "Payment failed");
        require(rhemToken.transfer(nfts[tokenId].owner, sellerAmount), "Seller payment failed");
        require(rhemToken.transfer(burnAddress, burnAmount), "Burn failed");
        require(rhemToken.transfer(devWallet, devAmount), "Dev fee failed");

        _transferNFT(nfts[tokenId].owner, msg.sender, tokenId);

        nfts[tokenId].listed = false;
        listings[tokenId].listed = false;

        emit NFTSold(msg.sender, tokenId, price);
    }

    function _transferNFT(address from, address to, uint256 tokenId) internal {
        nfts[tokenId].owner = to;

        uint256[] storage fromList = ownedNFTs[from];
        for (uint256 i = 0; i < fromList.length; i++) {
            if (fromList[i] == tokenId) {
                fromList[i] = fromList[fromList.length - 1];
                fromList.pop();
                break;
            }
        }

        ownedNFTs[to].push(tokenId);
    }
}
