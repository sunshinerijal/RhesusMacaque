// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract NFTMarketplace {
    struct NFT {
        address owner;
        string uri;
        bool listed;
        uint256 price;
    }

    address public dao;
    address public devWallet;
    address public burnAddress;
    IERC20 public rhemToken;

    uint256 public listingFee = 1e18; // 1 RHEM
    uint256 public saleFee = 75; // 0.75% (split as 0.5% burn + 0.25% dev)

    mapping(uint256 => NFT) public nfts;
    mapping(uint256 => bool) public stakedNFTs;
    mapping(address => uint256[]) public userStakes;

    uint256 public nextTokenId;

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    event NFTMinted(address indexed to, uint256 tokenId, string uri);
    event NFTListed(uint256 tokenId, uint256 price);
    event NFTUnlisted(uint256 tokenId);
    event NFTPurchased(address indexed buyer, uint256 tokenId, uint256 price);
    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);

    function initializeMarketplace(
        address _dao,
        address _devWallet,
        address _rhemToken,
        address _burnAddress
    ) public {
        require(dao == address(0), "Already initialized");
        require(_dao != address(0), "Invalid DAO");
        require(_devWallet != address(0), "Invalid dev wallet");
        require(_rhemToken != address(0), "Invalid token");

        dao = _dao;
        devWallet = _devWallet;
        rhemToken = IERC20(_rhemToken);
        burnAddress = _burnAddress;
    }

    function mintNFT(address to, string memory uri) external onlyDAO {
        uint256 tokenId = nextTokenId++;
        nfts[tokenId] = NFT(to, uri, false, 0);
        emit NFTMinted(to, tokenId, uri);
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        NFT storage nft = nfts[tokenId];
        require(nft.owner == msg.sender, "Not owner");
        require(price > 0, "Invalid price");
        require(!nft.listed, "Already listed");

        require(rhemToken.transferFrom(msg.sender, address(this), listingFee), "Fee payment failed");

        nft.listed = true;
        nft.price = price;

        emit NFTListed(tokenId, price);
    }

    function unlistNFT(uint256 tokenId) external {
        NFT storage nft = nfts[tokenId];
        require(nft.owner == msg.sender, "Not owner");
        require(nft.listed, "Not listed");

        nft.listed = false;
        nft.price = 0;

        emit NFTUnlisted(tokenId);
    }

    function buyNFT(uint256 tokenId) external {
        NFT storage nft = nfts[tokenId];
        require(nft.listed, "Not listed");
        require(msg.sender != nft.owner, "Cannot buy your own NFT");

        uint256 price = nft.price;
        uint256 burnAmount = (price * 50) / 10000; // 0.5%
        uint256 devAmount = (price * 25) / 10000;  // 0.25%
        uint256 sellerAmount = price - burnAmount - devAmount;

        require(rhemToken.transferFrom(msg.sender, nft.owner, sellerAmount), "Transfer to seller failed");
        require(rhemToken.transferFrom(msg.sender, burnAddress, burnAmount), "Burn failed");
        require(rhemToken.transferFrom(msg.sender, devWallet, devAmount), "Dev fee failed");

        nft.owner = msg.sender;
        nft.listed = false;
        nft.price = 0;

        emit NFTPurchased(msg.sender, tokenId, price);
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

    function updateListingFee(uint256 newFee) external onlyDAO {
        listingFee = newFee;
    }

    function updateSaleFee(uint256 newFee) external onlyDAO {
        require(newFee <= 500, "Too high"); // Max 5%
        saleFee = newFee;
    }
}
