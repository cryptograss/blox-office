// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import "../contracts/BlueRailroadTrainV2.sol";

contract DeployBlueRailroadV2Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address initialOwner = vm.addr(deployerPrivateKey);

        BlueRailroadTrainV2 blueRailroad = new BlueRailroadTrainV2(initialOwner);
        console.log("BlueRailroadTrainV2 deployed to:", address(blueRailroad));

        vm.stopBroadcast();
    }
}
