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
   function test_ReplayAttackWithChangedV() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        _vault.permitClaimPoints(user, value, deadline, v, r, s);
        assertEq(_points.balanceOf(user), 10000 * 10 ** 18);

        uint8 newV = v == 27 ? 28 : 27; 
        // vm.expectRevert();
        _vault.permitClaimPoints(user, value, deadline, newV, r, s);
    }
    function test_ReplayAttackWithChangedR() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        _vault.permitClaimPoints(user, value, deadline, v, r, s);
        assertEq(_points.balanceOf(user), 10000 * 10 ** 18);

        bytes32 newR = bytes32(uint256(r) + 1); 
        vm.expectRevert();
        _vault.permitClaimPoints(user, value, deadline, v, newR, s);
    }

    function test_ReplayAttackWithChangedS() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        _vault.permitClaimPoints(user, value, deadline, v, r, s);
        assertEq(_points.balanceOf(user), 10000 * 10 ** 18);

        bytes32 newS = bytes32(uint256(s) + 1);
        vm.expectRevert();
        _vault.permitClaimPoints(user, value, deadline, v, r, newS);
    }

    function test_ReplayAttackWithDifferentComponents() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(signerPrivateKey, digest);
        _vault.permitClaimPoints(user, value, deadline, v1, r1, s1);
        assertEq(_points.balanceOf(user), 10000 * 10 ** 18);

        bytes32 newR = bytes32(uint256(r1) + 1); 
        bytes32 newS = bytes32(uint256(s1) + 1);
        uint8 newV = v1 == 27 ? 28 : 27; 

        vm.expectRevert("sig used");
        _vault.permitClaimPoints(user, value, deadline, newV, newR, newS);
    }

    function test_SignatureWithDifferentPrivateKey() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        uint256 differentPrivateKey = uint256(keccak256(abi.encodePacked("different private key")));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(differentPrivateKey, digest);

        // vm.expectRevert("ERC2612InvalidSigner");
        _vault.permitClaimPoints(user, value, deadline, v, r, s);
    }


    function test_InvalidSignature() public {
        address user = address(2);
        uint value = 10000 * 10 ** 18;
        uint deadline = block.timestamp + 1200;

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

        uint8 invalidV = 28;
        bytes32 invalidR = bytes32(0);
        bytes32 invalidS = bytes32(0);

        // vm.expectRevert("ERC2612InvalidSigner");
        _vault.permitClaimPoints(user, value, deadline, invalidV, invalidR, invalidS);
    }


    function testFuzz_createVault(
        string memory vaultName,
        address vaultOwner,
        address paymentAddress,
        uint256 pointsAmountForVault
    ) public {
        vaultName = bytes(vaultName).length > 0 ? vaultName : "defaultVaultName";
        
        vm.startPrank(signer);
        uint256 currentBalance = _points.balanceOf(address(this));
        if (currentBalance < 1) {
            _points.mint(address(this), 1000000); 
            currentBalance = 1000000;
        }
        pointsAmountForVault = bound(pointsAmountForVault, 1, currentBalance - 1);

        bool success = _points.createVault(vaultName, vaultOwner, paymentAddress, pointsAmountForVault);
        assert(success);
        // assertEq(_points.nameVault(vaultName), true);

        (address vaultAddress, string memory name) = _points.vaultIdentifcation(_points.counterId() - 1);
        assertEq(vaultAddress != address(0), true);
        vm.stopPrank();
    }

    function testFuzz_createVaultTransfer(
        string memory vaultName,
        address vaultOwner,
        address paymentAddress,
        uint256 pointsAmountForVault
    ) public {
        vaultName = bytes(vaultName).length > 0 ? vaultName : "defaultVaultName";

        vm.startPrank(signer);
        uint256 currentBalance = _points.balanceOf(address(this));
        if (currentBalance < 1) {
            _points.mint(address(this), 1000000); 
            currentBalance = 1000000;
        }
        pointsAmountForVault = bound(pointsAmountForVault, 1, currentBalance - 1);

        uint256 initialBalance = _points.balanceOf(address(this));
        console.log("Initial Balance:", initialBalance);
        console.log("Points Amount for Vault:", pointsAmountForVault);

        bool success = _points.createVault(vaultName, vaultOwner, paymentAddress, pointsAmountForVault);
        assert(success);

        (address vaultAddress, ) = _points.vaultIdentifcation(_points.counterId() - 1);
        uint256 vaultBalance = _points.balanceOf(vaultAddress);
        uint256 afterTransferBalance = _points.balanceOf(address(this));

        console.log("After Transfer Balance:", afterTransferBalance);
        console.log("Expected After Transfer Balance:", initialBalance - pointsAmountForVault);
        console.log("Vault Address:", vaultAddress);
        console.log("Vault Balance:", vaultBalance);
        console.log("Final Balance:", _points.balanceOf(address(this)));

        assertEq(afterTransferBalance, initialBalance - pointsAmountForVault);
        assertEq(vaultBalance, pointsAmountForVault);

        vm.stopPrank();
    }


    function test_createVault_insufficientBalance() public {
        string memory vaultName = "TestVault";
        address vaultOwner = address(0x123);
        address paymentAddress = address(0x456);
        uint pointsAmountForVault = 40000000000000000000000000000000000;

        vm.startPrank(signer);

        // Ensure the contract has less balance than pointsAmountForVault
        uint initialBalance = _points.balanceOf(address(this));
        console.log("Initial Balance:", initialBalance);
        vm.assume(initialBalance < pointsAmountForVault);

        // Expect the transaction to revert due to insufficient balance
        console.log("Attempting to create vault with insufficient balance...");
        vm.expectRevert(); 
        _points.createVault(vaultName, vaultOwner, paymentAddress, pointsAmountForVault);
        
        vm.stopPrank();
    }


    function testFuzz_permitSwapToPaymentCoin_notEnoughPoints(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        pointToSwap = bound(pointToSwap, _points.balanceOf(user) + 1, type(uint256).max);
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);
        
        // Generate a valid signature
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                pointToSwap,
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
        
        (v, r, s) = vm.sign(signerPrivateKey, digest);
        
        // Expect revert due to insufficient points
        vm.expectRevert("not enough points");
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }

    function testFuzz_permitSwapToPaymentCoin_freezePermit(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        pointToSwap = bound(pointToSwap, 1, _points.balanceOf(user));
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);
        
        // Generate a valid signature
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                pointToSwap,
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
        
        (v, r, s) = vm.sign(signerPrivateKey, digest);
        
        // Freeze the contract
        _vault.freezeContract(true);
        
        // Expect revert due to contract freeze
        vm.expectRevert("contract freezed");
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }



    function testFuzz_permitSwapToPaymentCoin_lessThanMinPoints(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        uint256 pointsMin = 10000 * 10 ** 18;
        pointToSwap = bound(pointToSwap, 1, pointsMin - 1);
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);

        // Generate a valid signature for claim points
        (v, r, s) = generateValidSignature(user, pointsMin, deadline);

        // Claim points first
        _vault.permitClaimPoints(user, pointsMin, deadline, v, r, s);

        // Generate a valid signature for swap points
        (v, r, s) = generateValidSignature(user, pointToSwap, deadline);
        
        // Log the initial state
        console.log("Minimum Points Required:", pointsMin);
        console.log("Attempting to swap less than minimum points...");

        // Expect revert due to point amount less than minimum required
        vm.expectRevert("points to swap less than minpoints");
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }



    function testFuzz_permitSwapToPaymentCoin_invalidSignature(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        uint256 pointsMin = 10000 * 10 ** 18;
        uint256 userBalance = _points.balanceOf(user);
        if (userBalance < pointsMin) {
            prepareUserForTest(user, pointsMin);
            userBalance = pointsMin;
        }
        pointToSwap = bound(pointToSwap, pointsMin, userBalance);
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);
        
        // Use an invalid signature
        bytes32 invalidHash = keccak256(abi.encodePacked("invalid"));
        (v, r, s) = vm.sign(signerPrivateKey, invalidHash);
        
        // Log the initial state
        console.log("Attempting to swap with invalid signature...");

        // Expect revert due to invalid signature
        vm.expectRevert();
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }


    function testFuzz_permitSdwapToPaymentCoin_freezePermit(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        uint256 pointsMin = 10000 * 10 ** 18;
        uint256 userBalance = _points.balanceOf(user);
        if (userBalance < pointsMin) {
            prepareUserForTest(user, pointsMin);
            userBalance = pointsMin;
        }
        pointToSwap = bound(pointToSwap, pointsMin, userBalance);
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);

        // Generate a valid signature for claim points
        (v, r, s) = generateValidSignature(user, pointToSwap, deadline);

        // Claim points first
        _vault.permitClaimPoints(user, pointToSwap, deadline, v, r, s);

        // Generate a valid signature for swap points
        (v, r, s) = generateValidSignature(user, pointToSwap, deadline);
        
        // Freeze the contract
        _vault.freezeContract(true);
        
        // Log the initial state
        console.log("Initial Points Balance of Signer:", _points.balanceOf(signer));
        console.log("Worldcoin Balance of Vault:", _worldcoin.balanceOf(address(_vault)));
        console.log("Points Balance of Vault:", _points.balanceOf(address(_vault)));
        console.log("Attempting to swap with frozen contract...");

        // Expect revert due to contract freeze
        vm.expectRevert("contract freezed");
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }


    function testFuzz_RepermitRiopSwapToPaymentCoin_notEnoughPoints(
        address user,
        uint256 pointToSwap,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // Setup assumptions
        uint256 pointsMin = 10000 * 10 ** 18;
        uint256 userBalance = _points.balanceOf(user);
        pointToSwap = bound(pointToSwap, userBalance + 1, type(uint256).max);
        deadline = bound(deadline, block.timestamp + 1, block.timestamp + 365 days);

        // Generate a valid signature for claim points
        (v, r, s) = generateValidSignature(user, pointsMin, deadline);

        // Claim points first
        _vault.permitClaimPoints(user, pointsMin, deadline, v, r, s);

        // Generate a valid signature for swap points
        (v, r, s) = generateValidSignature(user, pointToSwap, deadline);

        // Log the initial state
        console.log("User Balance:", userBalance);
        console.log("Attempting to swap more points than user has...");

        // Expect revert due to insufficient points
        vm.expectRevert("not enough points");
        _vault.permitSwapToPaymentCoin(user, pointToSwap, deadline, v, r, s);
    }


    function testFuzz_withdrawfees_withNewDeposit(
        address feeTakerAddress,
        uint256 depositAmount
    ) public {
        vm.assume(feeTakerAddress != address(0));
        depositAmount = bound(depositAmount, 1, _worldcoin.balanceOf(signer)); 

        vm.startPrank(signer);
        _worldcoin.transfer(address(_vault), depositAmount);

        uint256 initialFeeTakerBalance = _worldcoin.balanceOf(feeTakerAddress);
        uint256 initialContractBalance = _worldcoin.balanceOf(address(_vault));
        uint256 initContractBalancePaymentCoin = _vault.initContractBalancePaymentCoin();
        uint256 claimedPaymentCoin = _vault.claimedPaymentCoin();
        uint256 TotalfeescollectedPaymentCoin = _vault.TotalfeescollectedPaymentCoin();

        uint256 contractBalance = initialContractBalance;
        uint256 balanceDeposited = (contractBalance + claimedPaymentCoin + TotalfeescollectedPaymentCoin) - initContractBalancePaymentCoin;
        uint256 fee = (balanceDeposited * _vault.depositFee()) / 100;
        uint256 expectedFeeTakerBalance = initialFeeTakerBalance + fee;
        uint256 expectedFinalContractBalance = contractBalance - fee;

        console.log("Initial Contract Balance:", initialContractBalance);
        console.log("Deposit Amount:", depositAmount);
        console.log("Initial Contract Balance Payment Coin:", initContractBalancePaymentCoin);
        console.log("Claimed Payment Coin:", claimedPaymentCoin);
        console.log("Total Fees Collected Payment Coin:", TotalfeescollectedPaymentCoin);
        console.log("Calculated Fee:", fee);
        console.log("Expected Fee Taker Balance:", expectedFeeTakerBalance);
        console.log("Expected Final Contract Balance:", expectedFinalContractBalance);

        _vault.withdrawfees(feeTakerAddress);

        uint256 finalFeeTakerBalance = _worldcoin.balanceOf(feeTakerAddress);
        uint256 finalContractBalance = _worldcoin.balanceOf(address(_vault));

        console.log("Final Fee Taker Balance:", finalFeeTakerBalance);
        console.log("Final Contract Balance:", finalContractBalance);

        assertEq(finalFeeTakerBalance, expectedFeeTakerBalance);
        assertEq(finalContractBalance, expectedFinalContractBalance);
        vm.stopPrank();
    }




    function testFuzz_withdrawfees_withoutNewDeposit(
        address feeTakerAddress
    ) public {
        vm.assume(feeTakerAddress != address(0));

        vm.expectRevert("no new deposit added");
        _vault.withdrawfees(feeTakerAddress);
    }




    function prepareUserForTest(address user, uint256 pointsAmount) internal {
        vm.startPrank(signer);
        _points.transfer(user, pointsAmount);
        vm.stopPrank();
    }

    function generateValidSignature(
        address user,
        uint256 amount,
        uint256 deadline
    ) internal returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                signer,
                user,
                amount,
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
        
        return vm.sign(signerPrivateKey, digest);
    }
}