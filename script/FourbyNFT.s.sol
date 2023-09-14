// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import "../src/FourbyNFT.sol";

contract FourbyScript is Script {
    function setUp() public {}

    function run() public {
      uint256 deployerPrivateKey = vm.envUint("FORGE_PRIVATE_KEY");
      address ownerAddress = vm.envAddress("FORGE_OWNER_ADDRESS");
      vm.startBroadcast(deployerPrivateKey);
      FourbyNFT nft = new FourbyNFT(ownerAddress);
      vm.stopBroadcast();
    }
}
