// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract NFTMarketplaceEvents {
    event Minted(address indexed owner, uint256 tokenId, string tokenURI);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTListed(address indexed owner, uint256 tokenId, uint256 price);
    event NFTUnlisted(uint256 tokenId);
    event NFTSold(address indexed buyer, uint256 tokenId, uint256 price);
    event ListingFeeUpdated(uint256 newFee);
    event SaleFeeUpdated(uint256 newFee);
    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);
}
