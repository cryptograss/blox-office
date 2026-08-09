// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import "contracts/MagicHat.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";


contract DeployMagicHatScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes32[] memory rabbitHashes = new bytes32[](2);
        // rabbitHashes[0] = keccak256(abi.encodePacked("rabbit1"));
        // rabbitHashes[1] = keccak256(abi.encodePacked("rabbit2"));

        rabbitHashes = new bytes32[](100);
        for (uint256 i = 0; i < 100; i++) {
            rabbitHashes[i] = keccak256(abi.encodePacked(Strings.toString(i)));
        }

        MagicHat magicHat = new MagicHat(rabbitHashes);

        console.log("MagicHat deployed to:", address(magicHat));

        vm.stopBroadcast();
    }
}
