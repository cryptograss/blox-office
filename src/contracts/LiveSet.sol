pragma solidity ^0.8.0;

contract LiveSet {
    bytes32[] public show_ids;
    mapping(bytes32 => mapping(uint8 => Set)) public sets; // for each show we have a list of sets

    struct Set {
        uint8 shape; // 0 = diamond, 1 = triangle, 2 = circle etc.
        uint8 order; // 0 = first, 1 = second, 2 = third etc.
        // bytes32[] rabbitHashes; // for each show we have a list of rabbit hashes
        uint256 stonePriceWei;
        bool isActive; // Always true
    }

    function addSet(
        uint16 artist_id,
        uint64 blockheight,
        uint8 shape,
        uint8 order,
        uint256 stonePriceWei) public onlyOwner {
        Set memory newSet = Set(shape, order, stonePriceWei, true);

        // Parse the show bytes into band ID and blockheight
        bytes32 showBytes =  bytes32(abi.encodePacked(artist_id,
            blockheight));

        show_ids.push(showBytes);
        sets[showBytes][newSet.order] = newSet;
    }



    function getShowIds() public view returns (bytes32[] memory) {
        return show_ids;
    }

    // --- Don't need that for now ---
    // function isValidShow(bytes32 showId) public view returns (bool) {
    //     return contains(show_ids, showId);
    // }

    // function contains(bytes32[] storage array, bytes32 value) internal view returns (bool) {
    //     for (uint i = 0; i < array.length; i++) {
    //         if (array[i] == value) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    function isValidSet(bytes32 showBytes, uint8 order) public view returns (bool) {
        // The result of querying the mapping with keys that has not been assigned a value will return default value for the type
        // for the Set struct, the default value of isActive is false
        return sets[showBytes][order].isActive;
    }

    function getSetForShow(uint16 artist_id, uint64 blockheight, uint8 order) public view returns (Set memory) {
        bytes32 showBytes = bytes32(abi.encodePacked(artist_id,
            blockheight));
        return sets[showBytes][order];
    }

    function getSetForShowByShowBytes(bytes32 showBytes, uint8 order) public view returns (Set memory) {
        return sets[showBytes][order];
    }

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

}