// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./NFTMarketplacePart1.sol";

contract NFTMarketplacePart2 is NFTMarketplacePart1 {
    uint256 public listingFee;
    uint256 public saleFee;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => address) public approvals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    struct Listing {
        uint256 price;
        address owner;
        bool listed;
    }

    event ListingFeeUpdated(uint256 newFee);
    event SaleFeeUpdated(uint256 newFee);

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
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
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

        // Remove from old owner's array
        uint256[] storage fromList = ownedNFTs[from];
        for (uint256 i = 0; i < fromList.length; i++) {
            if (fromList[i] == tokenId) {
                fromList[i] = fromList[fromList.length - 1];
                fromList.pop();
                break;
            }
        }

        ownedNFTs[to].push(tokenId);
        approvals[tokenId] = address(0); // Clear approval
    }
}
