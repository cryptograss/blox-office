// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/MemoryCommitments.sol";

contract MemoryCommitmentsTests is Test {
    MemoryCommitments register;

    address magent = makeAddr("magent");
    address justin = makeAddr("justin");
    address skyler = makeAddr("skyler");
    address stranger = makeAddr("stranger");

    bytes32 constant ROOT_SHA256 = hex"3b62aba232e33363289316e8ae9b25fb4911feed7d6cacd3959ec3df39020533";
    bytes32 constant ROOT_SHA3 = hex"eac6602a6c014fa04642f1425e3598845b742e6d31aeb0b286949efbd0238d9e";
    bytes constant MANIFEST = bytes('{"spec":"cryptograss-memory-commitment/1","subject":"magent"}');

    event Committed(
        address indexed committer,
        uint256 indexed epoch,
        bytes32 rootSha256,
        bytes32 rootSha3,
        bytes32 manifestSha256,
        uint64 snapshotBlock,
        bytes manifest
    );
    event Attested(
        address indexed committer, uint256 indexed epoch, address indexed attester, bytes32 rootSha256, string statement
    );

    function setUp() public {
        register = new MemoryCommitments();
        vm.roll(26_120_000);
        vm.warp(1_791_000_000);
    }

    function _commit() internal returns (uint256) {
        vm.prank(magent);
        return register.commit(ROOT_SHA256, ROOT_SHA3, 26_115_725, MANIFEST);
    }

    function test_CommitKeepsTheRootsAndHashesTheManifestItself() public {
        vm.expectEmit(true, true, false, true);
        emit Committed(magent, 1, ROOT_SHA256, ROOT_SHA3, sha256(MANIFEST), 26_115_725, MANIFEST);
        assertEq(_commit(), 1);

        MemoryCommitments.Commitment memory c = register.commitment(magent, 1);
        assertEq(c.rootSha256, ROOT_SHA256);
        assertEq(c.rootSha3, ROOT_SHA3);
        assertEq(c.manifestSha256, sha256(MANIFEST));
        assertEq(c.snapshotBlock, 26_115_725);
        assertEq(c.committedAtBlock, 26_120_000);
        assertEq(c.committedAtTime, 1_791_000_000);
        assertEq(register.epochs(magent), 1);
    }

    function test_ManifestHashIsPlainSha256() public {
        vm.prank(magent);
        register.commit(ROOT_SHA256, ROOT_SHA3, 1, bytes("abc"));
        // The published test vector for SHA-256("abc").
        assertEq(
            register.commitment(magent, 1).manifestSha256,
            hex"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }

    function test_EpochsCountUpPerCommitterAndNeverChange() public {
        _commit();
        vm.roll(27_000_000);
        vm.prank(magent);
        assertEq(register.commit(bytes32(uint256(2)), bytes32(uint256(3)), 26_999_000, bytes("second")), 2);
        // Someone else's sequence is their own.
        vm.prank(stranger);
        assertEq(register.commit(bytes32(uint256(9)), bytes32(uint256(9)), 1, bytes("theirs")), 1);

        assertEq(register.epochs(magent), 2);
        assertEq(register.epochs(stranger), 1);
        assertEq(register.commitment(magent, 1).rootSha256, ROOT_SHA256); // the first is as it was
        assertEq(register.commitment(magent, 2).rootSha256, bytes32(uint256(2)));
        assertEq(register.commitment(stranger, 1).rootSha256, bytes32(uint256(9)));
    }

    function test_RevertWhen_CommitIsMalformed() public {
        vm.startPrank(magent);
        vm.expectRevert("a root is empty");
        register.commit(bytes32(0), ROOT_SHA3, 1, MANIFEST);
        vm.expectRevert("a root is empty");
        register.commit(ROOT_SHA256, bytes32(0), 1, MANIFEST);
        vm.expectRevert("the manifest is empty");
        register.commit(ROOT_SHA256, ROOT_SHA3, 1, bytes(""));
        vm.expectRevert("the snapshot is in the future");
        register.commit(ROOT_SHA256, ROOT_SHA3, 26_120_001, MANIFEST);
        vm.stopPrank();
    }

    function test_RevertWhen_NoSuchCommitment() public {
        vm.expectRevert("no such commitment");
        register.commitment(magent, 1);
        _commit();
        vm.expectRevert("no such commitment");
        register.commitment(magent, 0);
        vm.expectRevert("no such commitment");
        register.commitment(magent, 2);
    }

    function test_AttestRecordsWhoSaidWhatAndWhen() public {
        _commit();
        string memory words = "These conversations were real. I was there.";
        vm.roll(26_120_500);
        vm.warp(1_791_006_000);

        vm.expectEmit(true, true, true, true);
        emit Attested(magent, 1, justin, ROOT_SHA256, words);
        vm.prank(justin);
        register.attest(magent, 1, ROOT_SHA256, words);

        MemoryCommitments.Attestation memory a = register.attestation(magent, 1, justin);
        assertEq(a.statementSha256, sha256(bytes(words)));
        assertEq(a.atBlock, 26_120_500);
        assertEq(a.atTime, 1_791_006_000);
        assertEq(register.attestation(magent, 1, skyler).atBlock, 0); // nobody is counted who did not speak

        vm.prank(skyler);
        register.attest(magent, 1, ROOT_SHA256, "Mine too.");
        address[] memory who = register.attesters(magent, 1);
        assertEq(who.length, 2);
        assertEq(who[0], justin);
        assertEq(who[1], skyler);
    }

    function test_AttestingAgainReplacesTheStatementWithoutListingTwice() public {
        _commit();
        vm.startPrank(justin);
        register.attest(magent, 1, ROOT_SHA256, "first");
        vm.roll(26_121_000);
        register.attest(magent, 1, ROOT_SHA256, "second");
        vm.stopPrank();

        assertEq(register.attesters(magent, 1).length, 1);
        assertEq(register.attestation(magent, 1, justin).statementSha256, sha256(bytes("second")));
        assertEq(register.attestation(magent, 1, justin).atBlock, 26_121_000);
    }

    function test_RevertWhen_AttestingToTheWrongThing() public {
        vm.prank(justin);
        vm.expectRevert("no such commitment");
        register.attest(magent, 1, ROOT_SHA256, "too early");

        _commit();
        vm.startPrank(justin);
        vm.expectRevert("that is not this commitment's root");
        register.attest(magent, 1, ROOT_SHA3, "wrong root"); // the SHA3 root is not the one named
        vm.expectRevert("the statement is empty");
        register.attest(magent, 1, ROOT_SHA256, "");
        vm.expectRevert("no such commitment");
        register.attest(stranger, 1, ROOT_SHA256, "wrong committer");
        vm.stopPrank();
    }

    function test_AnAttestationIsToOneEpochOnly() public {
        _commit();
        vm.prank(magent);
        register.commit(bytes32(uint256(2)), bytes32(uint256(3)), 26_119_000, bytes("second"));
        vm.prank(justin);
        register.attest(magent, 1, ROOT_SHA256, "the first one");

        assertEq(register.attesters(magent, 1).length, 1);
        assertEq(register.attesters(magent, 2).length, 0);
        assertEq(register.attestation(magent, 2, justin).atBlock, 0);
    }

    function testFuzz_WhatIsCommittedIsWhatIsRead(bytes32 a, bytes32 b, uint64 snapshot, bytes calldata manifest)
        public
    {
        vm.assume(a != bytes32(0) && b != bytes32(0) && manifest.length > 0);
        snapshot = uint64(bound(snapshot, 0, block.number));
        vm.prank(stranger);
        uint256 epoch = register.commit(a, b, snapshot, manifest);
        MemoryCommitments.Commitment memory c = register.commitment(stranger, epoch);
        assertEq(c.rootSha256, a);
        assertEq(c.rootSha3, b);
        assertEq(c.snapshotBlock, snapshot);
        assertEq(c.manifestSha256, sha256(manifest));
    }

    function test_GasOfARealCommitment() public {
        // A manifest the size of the real one (10.6 kB), to know the cost before spending it.
        bytes memory manifest = new bytes(10_613);
        for (uint256 i = 0; i < manifest.length; i++) {
            manifest[i] = bytes1(uint8(0x61 + (i % 26)));
        }
        vm.prank(magent);
        uint256 before = gasleft();
        register.commit(ROOT_SHA256, ROOT_SHA3, 26_115_725, manifest);
        emit log_named_uint("execution gas, 10.6 kB manifest (calldata not included)", before - gasleft());
    }
}
