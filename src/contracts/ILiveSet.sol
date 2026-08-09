// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiveSet {
    struct Set {
        uint8 shape; // 0 = diamond, 1 = triangle, 2 = circle etc.
        uint8 order; // 0 = first, 1 = second, 2 = third etc.
        uint256 stonePriceWei;
        bool isActive;
    }

    function getSetForShow(uint16 artist_id, uint64 blockheight, uint8 order) external view returns (Set memory);
    function getSetForShowByShowBytes(bytes32 showId, uint8 order) external view returns (Set memory);
    function getShowIds() external view returns (bytes32[] memory);
    // function isValidShow(bytes32 showId) external view returns (bool);
    function isValidSet(bytes32 showId, uint8 order) external view returns (bool);
}