import { expect } from "chai";
import { viem } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import type { Account, Address, WalletClient } from "viem";
import { getAddress } from "viem";
import BlueRailroadModule from "../ignition/modules/BlueRailroad";

async function deployBlueRailroadFixture() {
    const [deployer, otherAccount] = await viem.getWalletClients();

    const blueRailroad = await viem.deployContract("BlueRailroadV2", [
        deployer.account.address,
        "https://cryptograss.live/token-metadata/"
    ]);

    return { blueRailroad, deployer, otherAccount };
}

describe("BlueRailroad", function () {
    it("Sets the deployer as the owner", async function () {
        const { blueRailroad, deployer } = await loadFixture(deployBlueRailroadFixture);
        const owner = await blueRailroad.read.owner() as `0x${string}`;

        expect(getAddress(owner)).to.equal(getAddress(deployer.account.address));
    });

    it("Issues tokens with correct block height and track from 1979 Manzanita; dang that there's a good record", async function () {
        const { blueRailroad, deployer, otherAccount } = await loadFixture(deployBlueRailroadFixture);

        const issueParams = {
            squatter: otherAccount.account.address,
            songId: 7,  // Blue Railroad Train
            blockHeight: 21473487,
            metadataURI: "/7-blue-railroad"
        };

        await blueRailroad.write.issueTony([
            issueParams.squatter,
            issueParams.songId, // Track number, corresponds to the track number from the 1979 Manzanita record
            issueParams.blockHeight,
            issueParams.metadataURI
        ]);

        expect(await blueRailroad.read.tokenIdToSongId([1])).to.equal(issueParams.songId);
        expect(await blueRailroad.read.tokenIdToBlockHeight([1])).to.equal(issueParams.blockHeight);
        expect(await blueRailroad.read.ownerOf([1n])).to.equal(getAddress(issueParams.squatter));
    });

    it("Groups tokens by block height", async function () {
        const { blueRailroad, deployer } = await loadFixture(deployBlueRailroadFixture);

        const blockHeight = 21473487;
        await blueRailroad.write.issueTony([deployer.account.address, 7, blockHeight, "/7"]);
        await blueRailroad.write.issueTony([deployer.account.address, 7, blockHeight, "/8"]);

        expect(await blueRailroad.read.tokenIdToBlockHeight([1])).to.equal(blockHeight);
        expect(await blueRailroad.read.tokenIdToBlockHeight([2])).to.equal(blockHeight);
    });

    it("Fails when non-owner tries to issue tokens", async function () {
        const { blueRailroad, otherAccount } = await loadFixture(deployBlueRailroadFixture);
        await expect(blueRailroad.write.issueTony([
            otherAccount.account.address,
            7,
            21473487,
            "/7"
        ], { account: otherAccount.account })).to.be.rejectedWith("OwnableUnauthorizedAccount");
    });

    it("Fails with invalid song ID", async function () {
        const { blueRailroad, deployer } = await loadFixture(deployBlueRailroadFixture);
        await expect(blueRailroad.write.issueTony([
            deployer.account.address,
            0,
            21473487,
            "/0"
        ])).to.be.rejectedWith("Invalid song ID");
    });

    it("Allows owner to update base URI", async function () {
        const { blueRailroad, deployer } = await loadFixture(deployBlueRailroadFixture);

        await blueRailroad.write.issueTony([deployer.account.address, 7, 21473487, "7"]);
        await blueRailroad.write.setBaseMetadataURI(["https://new.cryptograss.live/metadata/"]);

        const tokenURI = await blueRailroad.read.tokenURI([1n]);
        expect(tokenURI).to.equal("https://new.cryptograss.live/metadata/7");
    });

    it("Handles multiple tokens for same user", async function () {
        const { blueRailroad, deployer } = await loadFixture(deployBlueRailroadFixture);

        // Issue multiple tokens
        await blueRailroad.write.issueTony([deployer.account.address, 7, 21473487, "/7-1"]);
        await blueRailroad.write.issueTony([deployer.account.address, 7, 21473487, "/7-2"]);
        await blueRailroad.write.issueTony([deployer.account.address, 7, 21473488, "/7-3"]);

        // Check balance
        expect(await blueRailroad.read.balanceOf([deployer.account.address])).to.equal(3n);

        // Check different block heights
        expect(await blueRailroad.read.tokenIdToBlockHeight([1])).to.equal(21473487);
        expect(await blueRailroad.read.tokenIdToBlockHeight([3])).to.equal(21473488);
    });

    it("Tracks and recognizes the squatter after token transfer", async function () {
        const { blueRailroad, deployer, otherAccount } = await loadFixture(deployBlueRailroadFixture);

        // Issue token to otherAccount (the squatter)
        await blueRailroad.write.issueTony([
            otherAccount.account.address,
            7,
            21474014,
            "/7"
        ]);

        // Transfer to deployer
        await blueRailroad.write.transferFrom(
            [otherAccount.account.address, deployer.account.address, 1n],
            { account: otherAccount.account }
        );

        // Current owner should be deployer
        expect(await blueRailroad.read.ownerOf([1n]))
            .to.equal(getAddress(deployer.account.address));

        expect(await blueRailroad.read.tokenIdToSquatter([1]))
            .to.equal(getAddress(otherAccount.account.address));
    });

});