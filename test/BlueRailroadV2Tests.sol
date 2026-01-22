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

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        blueRailroad = new BlueRailroadTrainV2(owner);
    }

    // ============ Minting Tests ============

    function test_mint_token_with_correct_metadata() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest123");

        assertEq(blueRailroad.ownerOf(0), alice);
        assertEq(blueRailroad.tokenIdToSongId(0), SQUATS);
        assertEq(blueRailroad.tokenIdToDate(0), 20260122);
        assertEq(blueRailroad.tokenURI(0), "ipfs://QmTest123");
        assertEq(blueRailroad.totalSupply(), 1);
    }

    function test_mint_multiple_tokens_increments_id() public {
        blueRailroad.issueTony(alice, SQUATS, 20260120, "ipfs://QmFirst");
        blueRailroad.issueTony(bob, PUSHUPS, 20260121, "ipfs://QmSecond");
        blueRailroad.issueTony(alice, ARMY_CRAWLS, 20260122, "ipfs://QmThird");

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
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest");
    }

    // ============ setSongId Tests ============

    function test_owner_can_update_song_id() public {
        blueRailroad.issueTony(alice, PUSHUPS, 20260122, "ipfs://QmTest");

        // Token was minted with wrong songId (5/Pushups), should be 7/Squats
        assertEq(blueRailroad.tokenIdToSongId(0), PUSHUPS);

        blueRailroad.setSongId(0, SQUATS);

        assertEq(blueRailroad.tokenIdToSongId(0), SQUATS);
    }

    function test_setSongId_emits_events() public {
        blueRailroad.issueTony(alice, PUSHUPS, 20260122, "ipfs://QmTest");

        vm.expectEmit(true, false, false, true);
        emit BlueRailroadTrainV2.SongIdUpdated(0, PUSHUPS, SQUATS);

        vm.expectEmit(false, false, false, true);
        emit IERC4906.MetadataUpdate(0);

        blueRailroad.setSongId(0, SQUATS);
    }

    function test_non_owner_cannot_update_song_id() public {
        blueRailroad.issueTony(alice, PUSHUPS, 20260122, "ipfs://QmTest");

        vm.prank(alice);
        vm.expectRevert();
        blueRailroad.setSongId(0, SQUATS);
    }

    function test_setSongId_reverts_for_nonexistent_token() public {
        vm.expectRevert("Token does not exist");
        blueRailroad.setSongId(999, SQUATS);
    }

    // ============ setDate Tests ============

    function test_owner_can_update_date() public {
        // Minted with Unix timestamp instead of YYYYMMDD format
        blueRailroad.issueTony(alice, SQUATS, 1705685808, "ipfs://QmTest");

        assertEq(blueRailroad.tokenIdToDate(0), 1705685808);

        blueRailroad.setDate(0, 20240119);

        assertEq(blueRailroad.tokenIdToDate(0), 20240119);
    }

    function test_setDate_emits_events() public {
        blueRailroad.issueTony(alice, SQUATS, 20260101, "ipfs://QmTest");

        vm.expectEmit(true, false, false, true);
        emit BlueRailroadTrainV2.DateUpdated(0, 20260101, 20260122);

        vm.expectEmit(false, false, false, true);
        emit IERC4906.MetadataUpdate(0);

        blueRailroad.setDate(0, 20260122);
    }

    function test_non_owner_cannot_update_date() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest");

        vm.prank(alice);
        vm.expectRevert();
        blueRailroad.setDate(0, 20260123);
    }

    function test_setDate_reverts_for_nonexistent_token() public {
        vm.expectRevert("Token does not exist");
        blueRailroad.setDate(999, 20260122);
    }

    // ============ setTokenURI Tests ============

    function test_owner_can_update_token_uri() public {
        // Minted with broken Discord URL
        blueRailroad.issueTony(alice, SQUATS, 20260122, "https://discord.com/broken");

        assertEq(blueRailroad.tokenURI(0), "https://discord.com/broken");

        blueRailroad.setTokenURI(0, "ipfs://QmCorrectVideo");

        assertEq(blueRailroad.tokenURI(0), "ipfs://QmCorrectVideo");
    }

    function test_setTokenURI_emits_metadata_update() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmOld");

        vm.expectEmit(false, false, false, true);
        emit IERC4906.MetadataUpdate(0);

        blueRailroad.setTokenURI(0, "ipfs://QmNew");
    }

    function test_non_owner_cannot_update_token_uri() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest");

        vm.prank(alice);
        vm.expectRevert();
        blueRailroad.setTokenURI(0, "ipfs://QmEvil");
    }

    function test_setTokenURI_reverts_for_nonexistent_token() public {
        vm.expectRevert("Token does not exist");
        blueRailroad.setTokenURI(999, "ipfs://QmTest");
    }

    // ============ ERC721 Standard Tests ============

    function test_token_holder_can_transfer() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest");

        vm.prank(alice);
        blueRailroad.transferFrom(alice, bob, 0);

        assertEq(blueRailroad.ownerOf(0), bob);
    }

    function test_token_holder_can_burn() public {
        blueRailroad.issueTony(alice, SQUATS, 20260122, "ipfs://QmTest");

        assertEq(blueRailroad.totalSupply(), 1);

        vm.prank(alice);
        blueRailroad.burn(0);

        assertEq(blueRailroad.totalSupply(), 0);
    }

    function test_enumerable_functions_work() public {
        blueRailroad.issueTony(alice, SQUATS, 20260120, "ipfs://Qm1");
        blueRailroad.issueTony(alice, PUSHUPS, 20260121, "ipfs://Qm2");
        blueRailroad.issueTony(bob, ARMY_CRAWLS, 20260122, "ipfs://Qm3");

        assertEq(blueRailroad.balanceOf(alice), 2);
        assertEq(blueRailroad.balanceOf(bob), 1);

        assertEq(blueRailroad.tokenOfOwnerByIndex(alice, 0), 0);
        assertEq(blueRailroad.tokenOfOwnerByIndex(alice, 1), 1);
        assertEq(blueRailroad.tokenOfOwnerByIndex(bob, 0), 2);

        assertEq(blueRailroad.tokenByIndex(0), 0);
        assertEq(blueRailroad.tokenByIndex(1), 1);
        assertEq(blueRailroad.tokenByIndex(2), 2);
    }

    // ============ EIP-4906 Support Test ============

    function test_supports_eip4906_interface() public view {
        // EIP-4906 interface ID is 0x49064906
        assertTrue(blueRailroad.supportsInterface(0x49064906));
    }

    function test_supports_erc721_interfaces() public view {
        // ERC721
        assertTrue(blueRailroad.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(blueRailroad.supportsInterface(0x5b5e139f));
        // ERC721Enumerable
        assertTrue(blueRailroad.supportsInterface(0x780e9d63));
    }

    // ============ Contract Metadata Tests ============

    function test_name_and_symbol() public view {
        assertEq(blueRailroad.name(), "Blue Railroad Train Squats");
        assertEq(blueRailroad.symbol(), "TONY");
    }
}
