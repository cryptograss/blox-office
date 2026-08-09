// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ILiveSet.sol";

contract SetStone is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {


    struct StoneColor {
        uint16 color1;
        uint16 color2;
        uint16 color3;
    }

    uint256 public numberOfStonesMinted;

    mapping(bytes32 => uint256[]) public stonesBySetId;
    mapping(uint256 => StoneColor) public stoneColorByTokenId;
    mapping(uint256 => string) public crystalizationMsgByTokenId;
    mapping(uint256 => uint256) public paidAmountWeiByTokenId;
    mapping(uint256 => uint8) public favoriteSongByTokenId;

    mapping(bytes32 => bytes32[]) public rabbitHashesByShow;
    mapping(bytes32 => uint8) public numberOfSetsInShow;
    mapping(bytes32 => uint8[]) public setShapeBySetId;
    mapping(bytes32 => uint256) public stonePriceByShow; // Someday, 0 might mean "auction" or "free" or "donation" or "not for sale"

    string public baseURI;

    constructor(address initialOwner, string memory base_uri) ERC721("SetStone", "STONE") Ownable(initialOwner) {
        numberOfStonesMinted = 0;
        baseURI = base_uri;
    }

    function getStoneColor(uint256 tokenId) public view returns (StoneColor memory) {
        return stoneColorByTokenId[tokenId];
    }

    function getCrystalizationMsg(uint256 tokenId) public view returns (string memory) {
        return crystalizationMsgByTokenId[tokenId];
    }

    function getPaidAmountWei(uint256 tokenId) public view returns (uint256) {
        return paidAmountWeiByTokenId[tokenId];
    }

    function getFavoriteSong(uint256 tokenId) public view returns (uint8) {
        return favoriteSongByTokenId[tokenId];
    }

    function getShowData(uint16 artist_id, uint64 blockheight) public view returns (bytes32, uint8, uint256, bytes32[] memory, uint8[] memory) {
        bytes32 showBytes = bytes32(abi.encodePacked(artist_id, blockheight));
        return (showBytes, numberOfSetsInShow[showBytes], stonePriceByShow[showBytes], rabbitHashesByShow[showBytes], setShapeBySetId[showBytes]);
    }

    function makeShowAvailableForStoneMinting(
        uint16 artist_id,
        uint64 blockheight,
        bytes32[] memory rabbitHashes,
        uint8 numberOfSets,
        uint8[] memory shapesBySetNumber, // Shape number, ordered by set number.
        uint256 stonePrice) public onlyOwner {

        // Check that number of sets match length of shapes array.
        require(numberOfSets == shapesBySetNumber.length, "Number of sets must match length of shapes array");


        // TODO: Authorized by artistID?
        bytes32 showBytes = bytes32(abi.encodePacked(artist_id,
            blockheight));
        rabbitHashesByShow[showBytes] = rabbitHashes;

        numberOfSetsInShow[showBytes] = numberOfSets;
        setShapeBySetId[showBytes] = shapesBySetNumber;
        stonePriceByShow[showBytes] = stonePrice;
    }

    function getRabbitHashesForShow(uint16 artist_id, uint64 blockheight) public view returns (bytes32[] memory) {
        bytes32 showBytes = bytes32(abi.encodePacked(artist_id,
            blockheight));
        return rabbitHashesByShow[showBytes];
    }

    function isValidRabbit(
        bytes32 rabbitHash,
        bytes32 showBytes
    ) public view returns (bool) {
        bytes32[] memory rabbitHashes = rabbitHashesByShow[showBytes];
        for (uint i = 0; i < rabbitHashes.length; i++) {
            if (rabbitHashes[i] == rabbitHash) {
                return true;
            }
        }
        return false;
    }

    function _burnRabbitHash(bytes32 showBytes, bytes32 rabbitHash) internal {
        bytes32[] memory rabbitHashes = rabbitHashesByShow[showBytes];
        for (uint i = 0; i < rabbitHashes.length; i++) {
            if (rabbitHashes[i] == rabbitHash) {
                rabbitHashesByShow[showBytes][i] = rabbitHashes[rabbitHashes.length - 1];
                rabbitHashesByShow[showBytes].pop();
                break;
            }
        }
    }

    function getSetId(uint16 artistId, uint64 blockHeight, uint8 order) public pure returns (bytes32) {
        return bytes32(abi.encodePacked(artistId, blockHeight, order));
    }


    function getStonesBySetId(uint16 artistId, uint64 blockHeight, uint8 order) public view returns (uint256[] memory) {
        return stonesBySetId[getSetId(artistId, blockHeight, order)];
    }


    function isColorAvailable(
        uint16 color1,
        uint16 color2,
        uint16 color3,
        bytes32 setId
    ) public view returns (bool) {
        // The color must not be already taken for the given set

        uint256[] memory stonesForSet = stonesBySetId[setId];

        // Iterate through all the setStones and check the color

        for (uint i = 0; i < stonesForSet.length; i++) {
            if (stoneColorByTokenId[stonesForSet[i]].color1 == color1 && stoneColorByTokenId[stonesForSet[i]].color2 == color2 && stoneColorByTokenId[stonesForSet[i]].color3 == color3) {
                return false;
            }
        }
        return true;
    }

    function _mintStone(
        address to,
        uint16 _color1,
        uint16 _color2,
        uint16 _color3,
        string memory _crystalization,
        uint8 _favoriteSong,
        bytes32 showBytes,
        bytes32 setId,
        bytes32 rabbitHash,
        string memory token_uri,
        uint256 paidAmountWei
    ) internal {


        // create the stone by adding it to the stones array
        stonesBySetId[setId].push(numberOfStonesMinted);
        stoneColorByTokenId[numberOfStonesMinted] = StoneColor({
            color1: _color1,
            color2: _color2,
            color3: _color3
        });
        crystalizationMsgByTokenId[numberOfStonesMinted] = _crystalization;
        paidAmountWeiByTokenId[numberOfStonesMinted] = paidAmountWei;
        favoriteSongByTokenId[numberOfStonesMinted] = _favoriteSong;

        // mint the stone
        _mint(to, numberOfStonesMinted);
        _setTokenURI(numberOfStonesMinted, token_uri);
        _burnRabbitHash(showBytes, rabbitHash);
        numberOfStonesMinted += 1;
    }

    function mintStoneForFree(
        address to,
        uint16 artistId,
        uint64 blockHeight,
        uint8 order,
        uint16 _color1,
        uint16 _color2,
        uint16 _color3,
        string memory _crystalization,
        uint8 _favoriteSong,
        string memory _rabbit_secret
    ) external onlyOwner {
        bytes32 showBytes = bytes32(abi.encodePacked(artistId, blockHeight));

        // check that the set exists and that the order is valid
        require(numberOfSetsInShow[showBytes] > order, "Set does not exist");

        // check that the secretRabbit is a valid secret for a given set
        bytes32 rabbitHash = keccak256(abi.encodePacked(_rabbit_secret));
        require(isValidRabbit(rabbitHash, showBytes), "Invalid secret rabbit");


        // --- Color checks ---
        bytes32 setId = getSetId(artistId, blockHeight, order);
        require(isColorAvailable(_color1, _color2, _color3, setId), "Color already taken for this set");

        string memory token_uri = Strings.toString(numberOfStonesMinted);
        _mintStone(to, _color1, _color2, _color3, _crystalization, _favoriteSong, showBytes, setId, rabbitHash, token_uri, 0);
    }

    function mintStone(
        address to,
        uint16 artistId,
        uint64 blockHeight,
        uint8 order,
        uint16 _color1,
        uint16 _color2,
        uint16 _color3,
        string memory _crystalization,
        uint8 _favoriteSong,
        string memory _rabbit_secret
    ) external payable {
        bytes32 showBytes = bytes32(abi.encodePacked(artistId, blockHeight));

        // check that the set exists and that the order is valid
        require(numberOfSetsInShow[showBytes] > order, "Set does not exist");

        // check that the payed amount is greater or equal to the stone price for the given set
        require(msg.value >= stonePriceByShow[showBytes], "Paid too little ETH for a setstone");
        // check that the secretRabbit is a valid secret for a given set
        bytes32 rabbitHash = keccak256(abi.encodePacked(_rabbit_secret));
        require(
            isValidRabbit(rabbitHash, showBytes),
            "Invalid secret rabbit"
        );


        // --- Color checks ---
        bytes32 setId = getSetId(artistId, blockHeight, order);
        require(isColorAvailable(_color1, _color2, _color3, setId), "Color already taken for this set");

        string memory token_uri = Strings.toString(numberOfStonesMinted);
        _mintStone(to, _color1, _color2, _color3, _crystalization, _favoriteSong, showBytes, setId, rabbitHash, token_uri, msg.value);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // ------
    // The following functions are overrides required by Solidity, because we are inheriting from multiple ERC721 implementations
    // ------
    function _increaseBalance(address to, uint128 value) internal override (ERC721Enumerable, ERC721) {
        super._increaseBalance(to, value);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }


    function _update(address to, uint256 tokenId, address auth) internal override (ERC721Enumerable, ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
    // TODO: shouldn't we somehow combine the implementations from both ERC721Enumerable and ERC721URIStorage?
    // as I understand it, super.supportsInterface(interfaceId) will select only one implementation
    // so the supported interface will be either that of ERC721Enumerable or ERC721URIStorage
    // but not both at the same time
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override (ERC721) returns (string memory) {
        return baseURI;
    }
}