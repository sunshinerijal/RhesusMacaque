// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract NFTMarketplaceEvents {
    event Minted(address indexed owner, uint256 indexed tokenId, string tokenURI);
    event Listed(uint256 indexed tokenId, uint256 price);
    event Unlisted(uint256 indexed tokenId);
    event Purchased(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ListingFeeUpdated(uint256 newFee);
    event SaleFeeUpdated(uint256 newFee);
    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);
}
