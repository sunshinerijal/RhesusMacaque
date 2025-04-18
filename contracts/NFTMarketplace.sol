// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface ICustomNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to, string calldata uri) external;
}

contract NFTMarketplace {
    address public nftContract;
    address public rhemToken;
    address public dao;
    address public devWallet;
    uint256 public listingFee;    // in wei
    uint256 public saleFee;       // in basis points (e.g., 100 = 1%)

    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(address indexed seller, uint256 indexed tokenId);
    event NFTPurchased(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 price);
    event FeesUpdated(uint256 listingFee, uint256 saleFee);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    constructor(address _nft, address _rhem, address _dao, address _devWallet) {
        require(_nft != address(0) && _rhem != address(0) && _dao != address(0) && _devWallet != address(0), "Invalid address");
        nftContract = _nft;
        rhemToken = _rhem;
        dao = _dao;
        devWallet = _devWallet;
        listingFee = 1e18; // 1 RHEM default
        saleFee = 75;      // 0.75% total (0.5% burn, 0.25% dev)
    }

    function updateFees(uint256 _listingFee, uint256 _saleFee) external onlyDAO {
        require(_saleFee <= 1000, "Too high fee");
        listingFee = _listingFee;
        saleFee = _saleFee;
        emit FeesUpdated(_listingFee, _saleFee);
    }

    function listNFT(uint256 tokenId, uint256 price) external {
        require(ICustomNFT(nftContract).ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Invalid price");
        require(IERC20(rhemToken).transferFrom(msg.sender, dao, listingFee), "Listing fee failed");

        listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(msg.sender, tokenId, price);
    }

    function unlistNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not seller");
        delete listings[tokenId];
        emit NFTUnlisted(msg.sender, tokenId);
    }

    function buyNFT(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "Not listed");

        uint256 fee = (listing.price * saleFee) / 10000;
        uint256 burnFee = (listing.price * 50) / 10000; // 0.5%
        uint256 devFee = fee - burnFee;
        uint256 sellerAmount = listing.price - fee;

        require(IERC20(rhemToken).transferFrom(msg.sender, address(this), listing.price), "Payment failed");
        require(IERC20(rhemToken).transfer(listing.seller, sellerAmount), "Payment to seller failed");
        require(IERC20(rhemToken).transfer(address(0), burnFee), "Burn failed");
        require(IERC20(rhemToken).transfer(devWallet, devFee), "Dev fee failed");

        ICustomNFT(nftContract).safeTransferFrom(listing.seller, msg.sender, tokenId);
        delete listings[tokenId];

        emit NFTPurchased(msg.sender, listing.seller, tokenId, listing.price);
    }

    function mintNFT(string calldata uri) external onlyDAO {
        ICustomNFT(nftContract).mint(dao, uri);
    }

    function getListing(uint256 tokenId) external view returns (address, uint256) {
        Listing memory listing = listings[tokenId];
        return (listing.seller, listing.price);
    }
}
