// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IERC721
 * @dev Standard ERC721 token interface, consolidated from contracts.
 */
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mintTo(address recipient, uint256 tokenId, string memory uri) external;
    function exists(uint256 tokenId) external view returns (bool);
}