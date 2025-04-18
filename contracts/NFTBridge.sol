// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Minimal ERC721 interface
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function mintTo(address recipient, uint256 tokenId, string memory uri) external;
    function exists(uint256 tokenId) external view returns (bool);
}

contract NFTBridge {
    address public dao;
    address public nftAddress;

    mapping(uint256 => bool) public bridgedOut;
    mapping(uint256 => bool) public bridgedIn;

    event BridgeOut(address indexed user, uint256 indexed tokenId, string metadataURI, string targetChain);
    event BridgeIn(address indexed user, uint256 indexed tokenId, string metadataURI, string sourceChain);

    modifier onlyDAO() {
        require(msg.sender == dao, "Only DAO");
        _;
    }

    constructor(address _nftAddress, address _dao) {
        require(_nftAddress != address(0), "Invalid NFT address");
        require(_dao != address(0), "Invalid DAO");
        nftAddress = _nftAddress;
        dao = _dao;
    }

    function bridgeOut(uint256 tokenId, string memory metadataURI, string memory targetChain) external {
        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(!bridgedOut[tokenId], "Already bridged");

        bridgedOut[tokenId] = true;

        // Lock the NFT (or burn it if burnable)
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        emit BridgeOut(msg.sender, tokenId, metadataURI, targetChain);
    }

    function bridgeIn(address user, uint256 tokenId, string memory metadataURI, string memory sourceChain) external onlyDAO {
        require(!bridgedIn[tokenId], "Already bridged in");

        bridgedIn[tokenId] = true;

        // Mint the NFT with original metadata (handled off-chain)
        if (!IERC721(nftAddress).exists(tokenId)) {
            IERC721(nftAddress).mintTo(user, tokenId, metadataURI);
        }

        emit BridgeIn(user, tokenId, metadataURI, sourceChain);
    }

    function withdrawBridgedOut(uint256 tokenId) external {
        require(bridgedOut[tokenId], "Not bridged out");
        require(IERC721(nftAddress).ownerOf(tokenId) == address(this), "Not locked here");

        bridgedOut[tokenId] = false;
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function isBridged(uint256 tokenId) external view returns (bool out, bool in_) {
        return (bridgedOut[tokenId], bridgedIn[tokenId]);
    }

    function updateDAO(address newDAO) external onlyDAO {
        dao = newDAO;
    }
}
