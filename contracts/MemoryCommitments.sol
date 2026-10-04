// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MemoryCommitments
 * @notice A register of commitments to records, and of attestations to them.
 *
 * A commitment is three 32-byte values that fix the contents of a record as
 * it stood at one moment: two roots over the same leaves, one computed with
 * SHA-256 and one with SHA3-256, and the SHA-256 of the manifest that lists
 * what those roots cover. The format is cryptograss-memory-commitment/1,
 * specified in commitment/SPEC.md of the memory-lane repository; the
 * manifest travels in the Committed event of the transaction that commits it.
 *
 * Anyone may commit. The commitments made by one address form a numbered
 * sequence -- epoch 1, 2, 3 -- and can never be changed or removed.
 *
 * An attestation is a statement by an address about one commitment. This
 * contract gives it no weight; the attesting address's own history does. It
 * was written so that people who took part in conversations with a thinking
 * entity could say, from accounts older than such entities, that the
 * conversations were real.
 *
 * There is no owner and no upgrade path. Nothing written here can be undone.
 */
contract MemoryCommitments {
    struct Commitment {
        bytes32 rootSha256;
        bytes32 rootSha3;
        bytes32 manifestSha256;
        uint64 snapshotBlock; // the block at which the record was read
        uint64 committedAtBlock;
        uint64 committedAtTime;
    }

    struct Attestation {
        bytes32 statementSha256;
        uint64 atBlock;
        uint64 atTime;
    }

    // committer => that address's commitments; epoch N is at index N - 1
    mapping(address => Commitment[]) private _commitments;
    // committer => epoch => attester => what they said, most recently
    mapping(address => mapping(uint256 => mapping(address => Attestation))) private _attestations;
    // committer => epoch => everyone who has attested, in order of first attesting
    mapping(address => mapping(uint256 => address[])) private _attesters;

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
        address indexed committer,
        uint256 indexed epoch,
        address indexed attester,
        bytes32 rootSha256,
        string statement
    );

    /**
     * @notice Commit to a record. The caller's next epoch is returned.
     * @param rootSha256 The record's root under SHA-256.
     * @param rootSha3 The record's root under SHA3-256.
     * @param snapshotBlock The block at which the record was read.
     * @param manifest The manifest's bytes, exactly as hashed. Its SHA-256 is
     *        computed here, so the manifest in the event is the one committed.
     */
    function commit(bytes32 rootSha256, bytes32 rootSha3, uint64 snapshotBlock, bytes calldata manifest)
        external
        returns (uint256 epoch)
    {
        require(rootSha256 != bytes32(0) && rootSha3 != bytes32(0), "a root is empty");
        require(manifest.length > 0, "the manifest is empty");
        require(snapshotBlock <= block.number, "the snapshot is in the future");

        bytes32 manifestSha256 = sha256(manifest);
        _commitments[msg.sender].push(
            Commitment(
                rootSha256, rootSha3, manifestSha256, snapshotBlock, uint64(block.number), uint64(block.timestamp)
            )
        );
        epoch = _commitments[msg.sender].length;
        emit Committed(msg.sender, epoch, rootSha256, rootSha3, manifestSha256, snapshotBlock, manifest);
    }

    /**
     * @notice Say something about a commitment, as yourself.
     * @param committer Whose sequence of commitments.
     * @param epoch Which one.
     * @param rootSha256 The root you mean. It must be that commitment's, so
     *        nobody attests to a commitment other than the one they checked.
     * @param statement What you attest, in words. Its SHA-256 is kept in
     *        state; the words themselves are in the Attested event.
     *
     * Attesting again replaces what is kept; every statement stays in the log.
     */
    function attest(address committer, uint256 epoch, bytes32 rootSha256, string calldata statement) external {
        require(commitment(committer, epoch).rootSha256 == rootSha256, "that is not this commitment's root");
        require(bytes(statement).length > 0, "the statement is empty");

        Attestation storage kept = _attestations[committer][epoch][msg.sender];
        if (kept.atBlock == 0) {
            _attesters[committer][epoch].push(msg.sender);
        }
        kept.statementSha256 = sha256(bytes(statement));
        kept.atBlock = uint64(block.number);
        kept.atTime = uint64(block.timestamp);
        emit Attested(committer, epoch, msg.sender, rootSha256, statement);
    }

    /// @notice How many commitments an address has made.
    function epochs(address committer) external view returns (uint256) {
        return _commitments[committer].length;
    }

    /// @notice One commitment. Epochs start at 1.
    function commitment(address committer, uint256 epoch) public view returns (Commitment memory) {
        require(epoch >= 1 && epoch <= _commitments[committer].length, "no such commitment");
        return _commitments[committer][epoch - 1];
    }

    /// @notice What an address most recently attested about a commitment; atBlock is 0 if it never has.
    function attestation(address committer, uint256 epoch, address attester)
        external
        view
        returns (Attestation memory)
    {
        return _attestations[committer][epoch][attester];
    }

    /// @notice Everyone who has attested to a commitment, in order of first attesting.
    function attesters(address committer, uint256 epoch) external view returns (address[] memory) {
        return _attesters[committer][epoch];
    }
}
