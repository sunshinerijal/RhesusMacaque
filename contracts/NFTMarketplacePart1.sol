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

contract NFTMarketplacePart1 {
    address public dao;
    address public devWallet;
    address public burnAddress;
    IERC20 public rhemToken;
    uint256 public totalSupply;

    mapping(uint256 => NFT) public nfts;
    mapping(address => uint256[]) public ownedNFTs;

    struct NFT {
        address owner;
        string tokenURI;
        bool listed;
    }

    event Minted(address indexed owner, uint256 tokenId, string tokenURI);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NFTListed(address indexed owner, uint256 tokenId, uint256 price);
    event NFTUnlisted(uint256 tokenId);
    event NFTSold(address indexed buyer, uint256 tokenId, uint256 price);

    modifier onlyDAO() {
        require(msg.sender == dao, "Not authorized");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(nfts[tokenId].owner == msg.sender, "Not the owner");
        _;
    }
}
