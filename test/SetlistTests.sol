// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "contracts/LiveSet.sol";

contract SetTest is Test {
    LiveSet set_contract;

    function setUp() public {
        set_contract = new LiveSet();
    }

    function testMakeSet() public {
        bytes32[] memory rabbitHashes = new bytes32[](2);
        rabbitHashes[0] = keccak256(abi.encodePacked("rabbit1"));
        rabbitHashes[1] = keccak256(abi.encodePacked("rabbit2"));

        uint16 artist_id = 0;
        uint64 blockheight = 420;

        set_contract.addSet({
            artist_id: artist_id,
            blockheight: blockheight,
            shape: 0,
            order: 0,
            stonePriceWei: 1 ether
        });

        bytes32 showBytes = bytes32(abi.encodePacked(artist_id, blockheight));

        LiveSet.Set memory this_set_in_particular = set_contract.getSetForShow(artist_id, blockheight, 0);
        assertEq(this_set_in_particular.shape, 0);
        assertEq(this_set_in_particular.stonePriceWei, 1 ether);
        bytes32 lets_see = set_contract.show_ids(0);
        assertEq(lets_see, showBytes);

        LiveSet.Set memory same_set_by_bytes = set_contract.getSetForShowByShowBytes(showBytes, 0);
        assertEq(same_set_by_bytes.shape, this_set_in_particular.shape);
        assertEq(same_set_by_bytes.order, this_set_in_particular.order);
    }
}
