// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Hardcoded ERC721 logic and Merkle Airdrop functionality
contract MerkleAirdropNFT {
    string public name = "MerkleAirdropNFT";
    string public symbol = "MANFT";
    uint256 public totalSupply;
    address public daoAddress;
    address public nftContract;
    bytes32 public merkleRoot; // Merkle Root for the airdrop

    mapping(address => bool) public hasClaimed;

    // Mapping of tokenId to owner
    mapping(uint256 => address) public owners;
    uint256 public nextTokenId = 1;

    event AirdropClaimed(address indexed user, uint256 indexed tokenId);

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this");
        _;
    }

    constructor(address _daoAddress) {
        daoAddress = _daoAddress;
    }

    // Initialize Merkle Root (Can only be called by DAO)
    function setMerkleRoot(bytes32 _root) external onlyDAO {
        merkleRoot = _root;
    }

    // Function to claim NFT based on Merkle proof
    function claimAirdrop(uint256 tokenId, bytes32[] calldata _merkleProof) external {
        require(!hasClaimed[msg.sender], "You have already claimed your NFT");
        require(verifyMerkleProof(msg.sender, _merkleProof), "Invalid proof");

        hasClaimed[msg.sender] = true;

        // Mint NFT (just assigning tokenId for simplicity)
        owners[tokenId] = msg.sender;
        totalSupply++;

        emit AirdropClaimed(msg.sender, tokenId);
    }

    // Merkle proof verification
    function verifyMerkleProof(address _account, bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account));
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < _merkleProof.length; i++) {
            computedHash = hashPair(computedHash, _merkleProof[i]);
        }

        return computedHash == merkleRoot;
    }

    // Helper function to hash pair of hashes
    function hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    // DAO-controlled functionality to mint additional NFTs if needed
    function mintNFT(address to) external onlyDAO {
        owners[nextTokenId] = to;
        nextTokenId++;
        totalSupply++;
    }

    // Optional: function to check ownership of a specific NFT
    function ownerOf(uint256 tokenId) external view returns (address) {
        return owners[tokenId];
    }
}
