// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/forge-std/src/Script.sol";
import "contracts/LiveSet.sol";
import "contracts/SetStone.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";


contract DeploySetStonesScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // TODO: how to get the address of the deployer?
        // We somehow need to get the address of the deployer PRIVATE KEY
        address initialOwner = vm.addr(deployerPrivateKey);

        SetStone setStone = new SetStone(initialOwner, "https://justinholmes.com/setstones/");
        console.log("SetStone deployed to:", address(setStone));

        vm.stopBroadcast();
    }
}
