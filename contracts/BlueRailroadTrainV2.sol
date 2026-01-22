// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BlueRailroadTrainV2
 * @notice Blue Railroad NFT contract for exercise challenge tokens
 * @dev Mints tokens representing completed exercises to Tony Rice's Manzanita album.
 *      Song IDs correspond to track numbers on Manzanita (1979):
 *      - Track 5: Nine Pound Hammer (Pushups)
 *      - Track 7: Blue Railroad Train (Squats)
 *      - Track 8: Ginseng Sullivan (Army Crawls)
 *
 *      V2 changes from V1:
 *      - Uses Ethereum blockheight instead of calendar date for temporal anchoring
 *      - Adds setBaseURI for future domain changes
 */
contract BlueRailroadTrainV2 is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    uint32 private _nextTokenId;

    /// @notice Maps token ID to Manzanita track number (5, 7, or 8)
    mapping(uint32 => uint32) public tokenIdToSongId;

    /// @notice Maps token ID to Ethereum mainnet blockheight when exercise was performed
    mapping(uint32 => uint256) public tokenIdToBlockheight;

    string private _baseTokenURI;

    constructor(address initialOwner)
        ERC721("Blue Railroad Train Squats", "TONY")
        Ownable(initialOwner)
    {}

    /**
     * @notice Mint a new Blue Railroad token
     * @param recipient Address to receive the token
     * @param songId Manzanita track number (5=Pushups, 7=Squats, 8=Army Crawls)
     * @param blockheight Ethereum mainnet blockheight when the exercise was performed
     * @param uri IPFS URI for the token's video content
     */
    function issueTony(address recipient, uint32 songId, uint256 blockheight, string memory uri) public onlyOwner {
        uint32 tokenId = _nextTokenId++;
        tokenIdToSongId[tokenId] = songId;
        tokenIdToBlockheight[tokenId] = blockheight;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Update the base URI for all tokens
     * @dev Useful if the domain or IPFS gateway changes. Only callable by owner.
     * @param newBaseURI The new base URI to prepend to token URIs
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @notice Returns the base URI for token metadata
     * @dev Overrides ERC721's _baseURI to use our configurable base
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // =========================================================================
    // Required overrides for multiple inheritance
    // =========================================================================
    // Solidity requires explicit overrides when a contract inherits from multiple
    // parents that define the same function. These all just delegate to super.

    /**
     * @dev Override required because both ERC721 and ERC721Enumerable define _update.
     *      Called on every transfer (including mint and burn) to update ownership tracking.
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Override required because both ERC721 and ERC721Enumerable define _increaseBalance.
     *      Called when minting to update the owner's token count.
     */
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    /**
     * @dev Override required because both ERC721 and ERC721URIStorage define tokenURI.
     *      Returns the full URI for a token's metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override required because ERC721, ERC721Enumerable, and ERC721URIStorage
     *      all define supportsInterface. Returns true if this contract implements
     *      the requested interface (ERC721, ERC721Enumerable, ERC721Metadata, ERC165).
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
