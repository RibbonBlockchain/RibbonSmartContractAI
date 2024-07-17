// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {points} from "../src/points.sol";
import {worldcoin} from "../src/testWorldcoin.sol";
contract PointScript is Script {
    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("DEV_PRIVATE_KEY");
        address account = vm.addr(privateKey);
        
        vm.startBroadcast(privateKey);
        worldcoin _worldcoin =new worldcoin();
        points _points=new points(account);
        console.log("pointaddress",address(_points));
       
        _points.createVault("vault1",account,address(_worldcoin),5000000000000000000000); 
      
       
        vm.stopBroadcast();
    }
}
