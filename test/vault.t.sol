// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {points} from "../src/points.sol";
import {worldcoin} from "../src/testWorldcoin.sol";
import {vault} from "../src/ribbonVault.sol";


contract VaultTest is Test {
    points public _points;
    worldcoin public _worldcoin;
    vault public _vault;
    uint256 internal signerPrivateKey;
    address signer;

    function setUp() public {
         signerPrivateKey = 0xabc123;
         signer = vm.addr(signerPrivateKey);
         vm.startPrank(signer);
         _points = new points(signer);
         _worldcoin =new worldcoin();
         console.log(_points.balanceOf(signer));
         _vault =  new vault(signer,"worldcoinvault",address(_worldcoin),address(_points));  
         _points.setApproveToburn(address(_vault),true);
         _points.transfer(address(_vault),500000000000000000000000);
         _worldcoin.transfer(address(_vault),100000000000000000000);
         console.log(_worldcoin.balanceOf(address(_vault)));
         vm.stopPrank();

    }

 
    // testing for the balance supplied to the vault
    function test_balanceOf() public view {
        assertEq(_points.balanceOf(address(_vault)),500000000000000000000000);
        assertEq(_worldcoin.balanceOf(address(_vault)),100000000000000000000);
    }
    
    // testing for admin to withdraw deposit fees when worldcoin deposit into the contract
    function test_withdrawfees()public{
        vm.startPrank(signer);
        // withdraw deposit fees when world coin deposits worldcoin test should pass
        _vault.withdrawfees(address(2));
        assertEq(_worldcoin.balanceOf(address(2)),10000000000000000000);
        
        // withdraw deposit fees when no new worldcoin deposits in the vault test should fail 
        vm.expectRevert();
        _vault.withdrawfees(address(2));
      
      // withdraw deposit fees when new worldcoin deposits in the vault test should pass
        _worldcoin.transfer(address(_vault),100000000000000000000);
         _vault.withdrawfees(address(2));
        assertEq(_worldcoin.balanceOf(address(2)),20000000000000000000);
      // withdraw deposit fees when no new worldcoin deposits in the vault test should fail 
         vm.expectRevert();
        _vault.withdrawfees(address(2));

        vm.startPrank(address(3));
        vm.expectRevert();
        _vault.withdrawfees(address(2));
    }  


    function test_Permitclaimpoints() public {
        address user = address(2);
        uint value = 10000* 10 ** 18;
        uint deadline = block.timestamp + 1200;
        console.log(deadline);

    
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                value,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _vault.DOMAIN_SEPARATOR(),
                structHash
            )
        );
     //   Admin signs some parameters then sends the signature to the user to use as verification onchain  for a user to claim points  
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey,digest);

    //   user passes the signature into the permitClaimPoints function it gets verifeid that it was the admin that signed it ,then points token is sent back 
    //   to the user this test should pass 
        _vault.permitClaimPoints(user,value,deadline,v,r,s);
        assertEq(_points.balanceOf(address(2)),10000* 10 ** 18);

    //   user wants to use the  signature twice to exploit the  contract the transaction will fail
        vm.expectRevert();
        _vault.permitClaimPoints(user,value,deadline,v,r,s);
    }
    
 

      function test_permitSwapToPaymentCoin() public {
        address user = address(2);
        uint value = 10000* 10 ** 18;
        uint deadline = block.timestamp + 1200;
        console.log(deadline);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                value,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _vault.DOMAIN_SEPARATOR(),
                structHash
            )
        );
   //   Admin signs some parameters then sends the signature to the user to use as verification onchain  for a user to claim points 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey,digest);
   //   user passes the signature into the permitClaimPoints function it gets verifeid that it was the admin that signed it ,then points token is sent back 
   //   to the user this test should pass 
        _vault.permitClaimPoints(user,value,deadline,v,r,s);
        

       
        
        uint deadline2 = block.timestamp + 3600;
        console.log(deadline2);

        // Sign the permit
        bytes32 structHash2 = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                value,
                deadline2
            )
        );

        bytes32 digest2 = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _vault.DOMAIN_SEPARATOR(),
                structHash2
            )
        );
    //   Admin signs some parameters then sends the signature to the user to use as verification onchain  for a user to swap Points to worldcoin at a specified rate
    // rate 5000 points = 1 world coin
        (uint8 vv, bytes32 rr, bytes32 ss) = vm.sign(signerPrivateKey,digest2);
   //   user passes the signature into the permitSwapToPaymentCoin function it gets verifeid that it was the admin that signed it ,then 10000 points token is swapped to 
   //   2 worldcoin  token  
        _vault.permitSwapToPaymentCoin(user,value,deadline2,vv,rr,ss);
         assertEq(_worldcoin.balanceOf(address(2)),2* 10 ** 18);
   
   //   user wants to use the  signature twice to exploit the  contract the transaction will fail
         vm.expectRevert();
        _vault.permitSwapToPaymentCoin(user,value,deadline2,vv,rr,ss);
    }
   
    }
    
   
    


