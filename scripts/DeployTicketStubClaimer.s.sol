// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Script.sol";
import "../contracts/TicketStubClaimer.sol";

/**
 * @title DeployTicketStubClaimer
 * @notice Foundry deploy script for TicketStubClaimer.
 *
 * Reads the deployer private key from PRIVATE_KEY env var, deploys the
 * contract, and (optionally) sets the base URI if BASE_URI is provided.
 * The deployer EOA becomes the contract owner — should be a cold/multisig
 * wallet (NOT the relayer hot wallet). The owner can later register stubs
 * via createTicketStubsForShow; the relayer pays gas to call
 * claimTicketStubFor on behalf of holders without crypto.
 *
 * Example (OP Sepolia rehearsal — chainId 11155420):
 *   PRIVATE_KEY=0x... \
 *     forge script scripts/DeployTicketStubClaimer.s.sol \
 *     --rpc-url https://sepolia.optimism.io --broadcast \
 *     --verify --etherscan-api-key $ETHERSCAN_API_KEY
 *
 * Example (Optimism mainnet — chainId 10):
 *   PRIVATE_KEY=0x... \
 *   BASE_URI=https://cryptograss.live/api/ticketstubs/ \
 *     forge script scripts/DeployTicketStubClaimer.s.sol \
 *     --rpc-url https://mainnet.optimism.io --broadcast \
 *     --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract DeployTicketStubClaimerScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        TicketStubClaimer claimer = new TicketStubClaimer(initialOwner);
        console.log("TicketStubClaimer deployed to:", address(claimer));
        console.log("Initial owner (deployer):", initialOwner);
        console.log("Chain ID:", block.chainid);

        // Optionally set base URI for token metadata if BASE_URI is provided.
        // Leave unset and call setBaseURI later if the metadata host isn't
        // ready at deploy time.
        string memory baseURI = vm.envOr("BASE_URI", string(""));
        if (bytes(baseURI).length > 0) {
            claimer.setBaseURI(baseURI);
            console.log("Base URI set to:", baseURI);
        } else {
            console.log("No BASE_URI provided; base URI left empty.");
            console.log("Call setBaseURI(string) later from the owner wallet.");
        }

        vm.stopBroadcast();
    }
}
