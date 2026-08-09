/**
 * @title BlueRailroadV2
 * @dev Deployed to amoy on Christmas Day 2024
 * "And the squats go round and round..." 🎄
 */

// blox-office/contracts/BlueRailroad-v2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlueRailroadV2 is ERC721URIStorage, Ownable {
    uint16 private _currentTokenId;
    mapping(uint16 => uint8) public tokenIdToSongId;
    mapping(uint16 => uint32) public tokenIdToBlockHeight;
    mapping(uint16 => string) public tokenIdToMetadataURI;
    mapping(uint16 => address) public tokenIdToSquatter;
    string public baseMetadataURI;

    constructor(
        address initialOwner,
        string memory _baseMetadataURI
    ) ERC721("CryptoGrass Performance", "CGPERF") Ownable(initialOwner) {
        baseMetadataURI = _baseMetadataURI;
    }

    function issueTony(
        address squatter,
        uint8 songId,
        uint32 blockHeight,
        string memory metadataURI
    ) public onlyOwner {
        require(songId > 0, "Invalid song ID");
        _currentTokenId += 1;
        uint16 tokenId = _currentTokenId;
        
        _safeMint(squatter, tokenId);
        tokenIdToSongId[tokenId] = songId;
        tokenIdToBlockHeight[tokenId] = blockHeight;
        tokenIdToMetadataURI[tokenId] = metadataURI;
        tokenIdToSquatter[tokenId] = squatter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return string(abi.encodePacked(baseMetadataURI, tokenIdToMetadataURI[uint16(tokenId)]));
    }

    function setBaseMetadataURI(string memory _newBaseURI) public onlyOwner {
        baseMetadataURI = _newBaseURI;
    }
}