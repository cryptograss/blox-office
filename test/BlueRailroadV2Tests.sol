// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/BlueRailroadTrainV2.sol";

contract BlueRailroadV2Tests is Test {
    BlueRailroadTrainV2 blueRailroad;
    address owner;
    address alice;
    address bob;

    // Manzanita track numbers
    uint32 constant PUSHUPS = 5;      // Nine Pound Hammer
    uint32 constant SQUATS = 7;       // Blue Railroad Train
    uint32 constant ARMY_CRAWLS = 8;  // Ginseng Sullivan

    // Sample blockheights (Ethereum mainnet)
    uint256 constant BLOCK_JAN_2024 = 19000000;
    uint256 constant BLOCK_JAN_2026 = 21500000;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        blueRailroad = new BlueRailroadTrainV2(owner);
    }

    // ============ Minting Tests ============

    function test_mint_token_with_correct_metadata() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2026, "ipfs://QmTest123");

        assertEq(blueRailroad.ownerOf(0), alice);
        assertEq(blueRailroad.tokenIdToSongId(0), SQUATS);
        assertEq(blueRailroad.tokenIdToBlockheight(0), BLOCK_JAN_2026);
        assertEq(blueRailroad.tokenURI(0), "ipfs://QmTest123");
        assertEq(blueRailroad.totalSupply(), 1);
    }

    function test_mint_multiple_tokens_increments_id() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2024, "ipfs://QmFirst");
        blueRailroad.issueTony(bob, PUSHUPS, BLOCK_JAN_2024 + 1000, "ipfs://QmSecond");
        blueRailroad.issueTony(alice, ARMY_CRAWLS, BLOCK_JAN_2026, "ipfs://QmThird");

        assertEq(blueRailroad.totalSupply(), 3);
        assertEq(blueRailroad.ownerOf(0), alice);
        assertEq(blueRailroad.ownerOf(1), bob);
        assertEq(blueRailroad.ownerOf(2), alice);

        assertEq(blueRailroad.tokenIdToSongId(0), SQUATS);
        assertEq(blueRailroad.tokenIdToSongId(1), PUSHUPS);
        assertEq(blueRailroad.tokenIdToSongId(2), ARMY_CRAWLS);
    }

    function test_only_owner_can_mint() public {
        vm.prank(alice);
        vm.expectRevert();
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2026, "ipfs://QmTest");
    }

    // ============ Base URI Tests ============

    function test_owner_can_set_base_uri() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2026, "QmTest123");

        // Initially no base URI
        assertEq(blueRailroad.tokenURI(0), "QmTest123");

        // Set base URI
        blueRailroad.setBaseURI("ipfs://");

        // Now token URI includes base
        assertEq(blueRailroad.tokenURI(0), "ipfs://QmTest123");
    }

    function test_non_owner_cannot_set_base_uri() public {
        vm.prank(alice);
        vm.expectRevert();
        blueRailroad.setBaseURI("https://evil.com/");
    }

    // ============ ERC721 Standard Tests ============

    function test_token_holder_can_transfer() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2026, "ipfs://QmTest");

        vm.prank(alice);
        blueRailroad.transferFrom(alice, bob, 0);

        assertEq(blueRailroad.ownerOf(0), bob);
    }

    function test_token_holder_can_burn() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2026, "ipfs://QmTest");

        assertEq(blueRailroad.totalSupply(), 1);

        vm.prank(alice);
        blueRailroad.burn(0);

        assertEq(blueRailroad.totalSupply(), 0);
    }

    function test_enumerable_functions_work() public {
        blueRailroad.issueTony(alice, SQUATS, BLOCK_JAN_2024, "ipfs://Qm1");
        blueRailroad.issueTony(alice, PUSHUPS, BLOCK_JAN_2024 + 500, "ipfs://Qm2");
        blueRailroad.issueTony(bob, ARMY_CRAWLS, BLOCK_JAN_2026, "ipfs://Qm3");

        assertEq(blueRailroad.balanceOf(alice), 2);
        assertEq(blueRailroad.balanceOf(bob), 1);

        assertEq(blueRailroad.tokenOfOwnerByIndex(alice, 0), 0);
        assertEq(blueRailroad.tokenOfOwnerByIndex(alice, 1), 1);
        assertEq(blueRailroad.tokenOfOwnerByIndex(bob, 0), 2);

        assertEq(blueRailroad.tokenByIndex(0), 0);
        assertEq(blueRailroad.tokenByIndex(1), 1);
        assertEq(blueRailroad.tokenByIndex(2), 2);
    }

    // ============ Interface Support Tests ============

    function test_supports_erc721_interfaces() public view {
        // ERC721
        assertTrue(blueRailroad.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(blueRailroad.supportsInterface(0x5b5e139f));
        // ERC721Enumerable
        assertTrue(blueRailroad.supportsInterface(0x780e9d63));
        // ERC165
        assertTrue(blueRailroad.supportsInterface(0x01ffc9a7));
    }

    // ============ Contract Metadata Tests ============

    function test_name_and_symbol() public view {
        assertEq(blueRailroad.name(), "Blue Railroad Train Squats");
        assertEq(blueRailroad.symbol(), "TONY");
    }
}
