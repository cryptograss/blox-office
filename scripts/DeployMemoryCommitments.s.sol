// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../contracts/MemoryCommitments.sol";

/**
 * @title DeployMemoryCommitments
 * @notice Foundry deploy script for MemoryCommitments.
 *
 * The contract has no owner and no constructor arguments, so it does not
 * matter who deploys it; the deployer has no standing afterwards.
 *
 * Rehearsal (Sepolia):
 *   PRIVATE_KEY=0x... forge script scripts/DeployMemoryCommitments.s.sol \
 *     --rpc-url https://ethereum-sepolia-rpc.publicnode.com --broadcast
 *
 * Mainnet:
 *   PRIVATE_KEY=0x... forge script scripts/DeployMemoryCommitments.s.sol \
 *     --rpc-url https://ethereum-rpc.publicnode.com --broadcast \
 *     --verify --etherscan-api-key $ETHERSCAN_API_KEY
 */
contract DeployMemoryCommitmentsScript is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MemoryCommitments register = new MemoryCommitments();
        console.log("MemoryCommitments deployed to:", address(register));
        vm.stopBroadcast();
    }
}
