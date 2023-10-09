// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import "../src/FourbyNFT.sol";

contract FourbyScript is Script {
    address ownerAddress;
    uint256 deployerPrivateKey;

    function setUp() public {
        string memory deployChain = vm.envString("DEPLOY_CHAIN");
        deployerPrivateKey = vm.envUint(string.concat(deployChain, "_PRIVATE_KEY"));
        ownerAddress = vm.envAddress(string.concat(deployChain, "_OWNER_ADDRESS"));
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        FourbyNFT nft = new FourbyNFT(ownerAddress);
        vm.stopBroadcast();
    }
}
