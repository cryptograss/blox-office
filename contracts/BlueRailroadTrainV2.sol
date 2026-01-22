// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";

/**
 * @title BlueRailroadTrainV2
 * @notice Blue Railroad NFT contract with metadata correction capabilities
 * @dev V2 adds setSongId, setDate, and setTokenURI functions for fixing minting errors.
 *      Song IDs correspond to track numbers on Tony Rice's Manzanita album (1979):
 *      - Track 5: Nine Pound Hammer (Pushups)
 *      - Track 7: Blue Railroad Train (Squats)
 *      - Track 8: Ginseng Sullivan (Army Crawls)
 */
contract BlueRailroadTrainV2 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, IERC4906 {
    uint32 private _nextTokenId;
    mapping(uint32 => uint32) public tokenIdToSongId;
    mapping(uint32 => uint32) public tokenIdToDate;

    /// @notice Emitted when a token's song ID is updated
    event SongIdUpdated(uint256 indexed tokenId, uint32 oldSongId, uint32 newSongId);

    /// @notice Emitted when a token's date is updated
    event DateUpdated(uint256 indexed tokenId, uint32 oldDate, uint32 newDate);

    constructor(address initialOwner)
        ERC721("Blue Railroad Train Squats", "TONY")
        Ownable(initialOwner)
    {}

    /**
     * @notice Mint a new Blue Railroad token
     * @param recipient Address to receive the token
     * @param songId Manzanita track number (5=Pushups, 7=Squats, 8=Army Crawls)
     * @param date Date in YYYYMMDD format (e.g., 20260122)
     * @param uri IPFS URI for the token metadata/video
     */
    function issueTony(address recipient, uint32 songId, uint32 date, string memory uri) public onlyOwner {
        uint32 tokenId = _nextTokenId++;
        tokenIdToSongId[tokenId] = songId;
        tokenIdToDate[tokenId] = date;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Update the song ID for an existing token
     * @dev Only callable by contract owner. Emits MetadataUpdate per EIP-4906.
     * @param tokenId The token to update
     * @param newSongId New Manzanita track number
     */
    function setSongId(uint32 tokenId, uint32 newSongId) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        uint32 oldSongId = tokenIdToSongId[tokenId];
        tokenIdToSongId[tokenId] = newSongId;
        emit SongIdUpdated(tokenId, oldSongId, newSongId);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @notice Update the date for an existing token
     * @dev Only callable by contract owner. Emits MetadataUpdate per EIP-4906.
     * @param tokenId The token to update
     * @param newDate New date in YYYYMMDD format
     */
    function setDate(uint32 tokenId, uint32 newDate) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        uint32 oldDate = tokenIdToDate[tokenId];
        tokenIdToDate[tokenId] = newDate;
        emit DateUpdated(tokenId, oldDate, newDate);
        emit MetadataUpdate(tokenId);
    }

    /**
     * @notice Update the token URI for an existing token
     * @dev Only callable by contract owner. Emits MetadataUpdate per EIP-4906.
     * @param tokenId The token to update
     * @param newUri New IPFS URI
     */
    function setTokenURI(uint256 tokenId, string memory newUri) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        _setTokenURI(tokenId, newUri);
        emit MetadataUpdate(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}
