// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./NFTMarketplacePart2.sol";

contract NFTMarketplacePart3 is NFTMarketplacePart2 {
    mapping(uint256 => bool) public stakedNFTs;
    mapping(address => uint256[]) public userStakes;

    event NFTStaked(address indexed user, uint256 tokenId);
    event NFTUnstaked(address indexed user, uint256 tokenId);

    function stakeNFT(uint256 tokenId) external {
        require(nfts[tokenId].owner == msg.sender, "Not owner");
        require(!stakedNFTs[tokenId], "Already staked");

        stakedNFTs[tokenId] = true;
        userStakes[msg.sender].push(tokenId);

        emit NFTStaked(msg.sender, tokenId);
    }

    function unstakeNFT(uint256 tokenId) external {
        require(nfts[tokenId].owner == msg.sender, "Not owner");
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

    function initializeMarketplace(
        address _dao,
        address _devWallet,
        address _rhemToken,
        address _burnAddress
    ) public {
        require(dao == address(0), "Already initialized");
        require(_dao != address(0), "Invalid DAO");
        require(_devWallet != address(0), "Invalid dev wallet");
        require(_rhemToken != address(0), "Invalid RHEM token");

        dao = _dao;
        devWallet = _devWallet;
        rhemToken = IERC20(_rhemToken);
        burnAddress = _burnAddress;
    }
}
