// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../contracts/BlueRailroadTrainV2.sol";

/**
 * @title DeployBlueRailroadV2Script
 * @notice Deploys BlueRailroadTrainV2 contract to Optimism
 * @dev Run with:
 *      forge script scripts/DeployBlueRailroadV2.s.sol --rpc-url $OPTIMISM_RPC --broadcast --verify
 *
 * After deployment:
 * 1. Holders burn their V1 tokens (0xCe09A2d0d0BDE635722D8EF31901b430E651dB52)
 * 2. Owner mints new tokens on V2 with correct metadata:
 *    - Use blockheight instead of date
 *    - Use correct songId (7 for Squats, not 5)
 *    - Use IPFS URIs (not Discord links)
 */
contract DeployBlueRailroadV2Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address initialOwner = vm.addr(deployerPrivateKey);

        BlueRailroadTrainV2 blueRailroad = new BlueRailroadTrainV2(initialOwner);
        console.log("BlueRailroadTrainV2 deployed to:", address(blueRailroad));
        console.log("Owner:", initialOwner);

        vm.stopBroadcast();
    }
}
