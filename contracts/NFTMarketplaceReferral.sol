// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTMarketplace {

    address public dao;
    uint256 public listingFee = 0.01 ether;
    uint256 public referralFee = 5; // 5% referral fee
    address public token;  // Address of the ERC20 token (for referral rewards)
    mapping(address => uint256) public referralRewards;
    mapping(address => address) public referrers;
    mapping(address => mapping(uint256 => uint256)) public nftListings; // Mapping to track listings by seller and tokenId

    event Listed(address indexed seller, uint256 tokenId, uint256 price);
    event Purchased(address indexed buyer, uint256 tokenId, uint256 price);
    event ReferralReward(address indexed referrer, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO can call");
        _;
    }

    modifier onlyOwnerOfNFT(address nftAddress, uint256 tokenId) {
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "You must own the NFT to list it");
        _;
    }

    constructor(address _dao, address _token) {
        dao = _dao;
        token = _token;
    }

    // Function to list an NFT
    function listNFT(address nftAddress, uint256 tokenId, uint256 price) external payable onlyOwnerOfNFT(nftAddress, tokenId) {
        require(msg.value >= listingFee, "Insufficient listing fee");
        require(price > 0, "Price must be greater than zero");
        require(nftListings[msg.sender][tokenId] == 0, "NFT already listed");

        nftListings[msg.sender][tokenId] = price; // Set the price for the NFT

        // Logic to list the NFT
        emit Listed(msg.sender, tokenId, price);
    }

    // Function to purchase an NFT
    function purchaseNFT(address nftAddress, uint256 tokenId) external payable {
        address seller = IERC721(nftAddress).ownerOf(tokenId); // Get the seller of the NFT
        uint256 price = nftListings[seller][tokenId]; // Get the price of the NFT

        require(price > 0, "Invalid NFT price");
        require(msg.value >= price, "Insufficient funds to purchase");

        uint256 referralReward = (msg.value * referralFee) / 100;

        // Handle the referral rewards
        address referrer = referrers[msg.sender];
        if (referrer != address(0)) {
            referralRewards[referrer] += referralReward;
            bool referralSuccess = IERC20(token).transfer(referrer, referralReward);
            require(referralSuccess, "Referral transfer failed");
            emit ReferralReward(referrer, referralReward);
        }

        uint256 sellerAmount = msg.value - referralReward;

        // Transfer the remaining amount to the seller
        (bool sent, ) = seller.call{value: sellerAmount}("");
        require(sent, "Failed to send Ether to the seller");

        // Remove the listing after the purchase
        delete nftListings[seller][tokenId];

        // Transfer NFT to the buyer
        IERC721(nftAddress).transferFrom(seller, msg.sender, tokenId);

        emit Purchased(msg.sender, tokenId, price);
    }

    // Function for users to claim their referral rewards
    function claimReferralRewards() external {
        uint256 reward = referralRewards[msg.sender];
        require(reward > 0, "No rewards available");
        referralRewards[msg.sender] = 0;

        bool success = IERC20(token).transfer(msg.sender, reward);
        require(success, "Referral claim failed");
    }

    // Function to set referrer for a user
    function setReferrer(address referrer) external {
        require(referrers[msg.sender] == address(0), "Referrer already set");
        require(referrer != msg.sender, "Cannot refer yourself");
        referrers[msg.sender] = referrer;
    }

    // DAO function to update the listing fee
    function updateListingFee(uint256 newFee) external onlyDAO {
        require(newFee > 0, "Listing fee must be greater than zero");
        listingFee = newFee;
    }

    // DAO function to update the referral fee
    function updateReferralFee(uint256 newFee) external onlyDAO {
        require(newFee <= 100, "Referral fee must be between 0 and 100");
        referralFee = newFee;
    }

    // Withdraw any accidentally sent Ether to the DAO
    function withdrawEther() external onlyDAO {
        (bool success, ) = dao.call{value: address(this).balance}("");
        require(success, "Failed to withdraw Ether");
    }
}
