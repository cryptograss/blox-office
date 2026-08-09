// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "lib/forge-std/src/Script.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

event RabbitHash(bytes32 indexed hash);

contract DeployScript is Script {
    function run() external {
        bytes32[] memory rabbitHashes = new bytes32[](100);

        rabbitHashes = new bytes32[](100);
        for (uint256 i = 0; i < 100; i++) {
            rabbitHashes[i] = keccak256(abi.encodePacked(Strings.toString(i)));
            emit RabbitHash(rabbitHashes[i]);
        }
    }
}
