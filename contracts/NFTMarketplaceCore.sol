// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./NFTMarketplaceStorage.sol";
import "./NFTMarketplaceEvents.sol";

contract NFTMarketplaceCore is NFTMarketplaceStorage, NFTMarketplaceEvents {

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

    function mint(string memory _uri) external onlyDAO returns (uint256) {
        totalSupply++;
        uint256 tokenId = totalSupply;

        nfts[tokenId] = NFT(msg.sender, _uri, false);
        ownedNFTs[msg.sender].push(tokenId);

        emit Minted(msg.sender, tokenId, _uri);
        return tokenId;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(nfts[tokenId].owner != address(0), "Token does not exist");
        return nfts[tokenId].tokenURI;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return ownedNFTs[owner].length;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return nfts[tokenId].owner;
    }

    function approve(address to, uint256 tokenId) public onlyOwnerOf(tokenId) {
        approvals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return approvals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        operatorStatus[msg.sender][operator] = approved ? ApprovalStatus.Approved : ApprovalStatus.Revoked;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorStatus[owner][operator] == ApprovalStatus.Approved;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(
            msg.sender == from ||
            approvals[tokenId] == msg.sender ||
            isApprovedForAll(from, msg.sender),
            "Not authorized"
        );
        require(nfts[tokenId].owner == from, "Invalid owner");

        _transferNFT(from, to, tokenId);
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
        approvals[tokenId] = address(0);
    }

    function listNFT(uint256 tokenId, uint256 price) external onlyOwnerOf(tokenId) {
        require(price > 0, "Price must be > 0");

        listings[tokenId] = Listing(price, msg.sender, true);
        emit Listed(tokenId, price);
    }

    function unlistNFT(uint256 tokenId) external onlyOwnerOf(tokenId) {
        listings[tokenId].listed = false;
        emit Unlisted(tokenId);
    }

    function purchaseNFT(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.listed, "Not listed");

        uint256 price = listing.price;
        uint256 feeAmount = (price * saleFee) / 10000;
        uint256 sellerAmount = price - feeAmount;

        require(rhemToken.transferFrom(msg.sender, listing.owner, sellerAmount), "Payment to seller failed");
        require(rhemToken.transferFrom(msg.sender, burnAddress, feeAmount / 2), "Burn fee failed");
        require(rhemToken.transferFrom(msg.sender, devWallet, feeAmount / 2), "Dev fee failed");

        _transferNFT(listing.owner, msg.sender, tokenId);
        listings[tokenId].listed = false;

        emit Purchased(msg.sender, tokenId, price);
    }

    function setListingFee(uint256 newFee) external onlyDAO {
        require(newFee <= 1000, "Fee too high"); // max 10%
        listingFee = newFee;
        emit ListingFeeUpdated(newFee);
    }

    function setSaleFee(uint256 newFee) external onlyDAO {
        require(newFee <= 1000, "Fee too high");
        saleFee = newFee;
        emit SaleFeeUpdated(newFee);
    }

    function stakeNFT(uint256 tokenId) external onlyOwnerOf(tokenId) {
        require(!stakedNFTs[tokenId], "Already staked");

        stakedNFTs[tokenId] = true;
        userStakes[msg.sender].push(tokenId);

        emit NFTStaked(msg.sender, tokenId);
    }

    function unstakeNFT(uint256 tokenId) external onlyOwnerOf(tokenId) {
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
}
