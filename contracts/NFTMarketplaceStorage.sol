// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract NFTMarketplaceStorage {
    address public dao;
    address public devWallet;
    address public burnAddress;
    IERC20 public rhemToken;

    uint256 public totalSupply;
    uint256 public listingFee;
    uint256 public saleFee;

    enum ApprovalStatus { None, Approved, Revoked }

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

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public ownedNFTs;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => address) public approvals;
    mapping(address => mapping(address => ApprovalStatus)) public operatorStatus;
    mapping(uint256 => bool) public stakedNFTs;
    mapping(address => uint256[]) public userStakes;

    bool internal locked;

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyDAO() {
        require(msg.sender == dao, "Not DAO");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(nfts[tokenId].owner == msg.sender, "Not token owner");
        _;
    }
}
