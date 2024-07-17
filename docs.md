# Overview
## Ribbon Protocol
### Welcome to the Ribbon Protocol documentation.
### This section contains technical details of Ribbon Protocol contracts running on the optimism chain

## Resources
+ Points.sol 
+ ribbonVault.sol

# Deployment Addresses 
## Sepolia Optimism Testnet

| contract               | Address                                     |
| -----------            | -----------                                 |
|  Points                | 0x28B841ab4C9fAD21ee837a66d8F533FF97CecaFF  |
|  WorldcoinVault        | 0x19DDd4cD2880f7521a60F1B30c3e558DC0630c98  | 

# Configure Your Local Environment

## Installation
OS - linux

```
curl -L https://foundry.paradigm.xyz | bash

foundryup
```
ℹ️ Note

If you’re on Windows, you will need to install and use Git BASH or WSL, as your terminal, since Foundryup currently does not support Powershell or Cmd.

## Setup

Clone the repository:

```
git clone https://github.com/RibbonBlockchain/RibbonSmartContract.git
cd RibbonSmartContract
code .
```
To run tests:
```
 cd test
 forge test -vvvv
 
```
## Deployment
1. create a .env 
2. add rpc in the .env  SEPOLIA_OPTIMISM_RPC
ℹ️ Note : you can get rpc from alchemy 
3. add your private key in your .env file

### .env file
```
SEPOLIA_OPTIMISM_RPC = 
DEV_PRIVATE_KEY = 0x83b446
```

run this command for deployment:
```
source .env

forge script script/points.s.sol:PointScript --rpc-url $SEPOLIA_OPTIMISM_RPC --broadcast

```
ℹ️ Note : reward token == worldcoin token
# Create Vault
## Points.sol
### For vault creation for different reward partners where points token and reward token are deposited into for claiming 
```javascript

function createVault(string memory vaultName,address vaultOwner,address paymentAddress,uint pointsAmountForVault)public  returns(bool){
    //...
    }
```
### Parameters
#### vaultName
The name of the vault to be created
#### vaultOwner
The admin  of the vault to be created
### paymentAddress
The contract address of the reward token to be transfered into the vault
### pointsAmountForVault
The Amount of points to be transfered in to the vault

# permitClaimPoints
## ribbonVault.sol
### For claiming of points onchain by converting virtual points gotten offchain to onchain points  
```javascript

function permitClaimPoints(address user,uint amount,uint256 deadline,uint8 v,bytes32 r,bytes32 s)public  {
          //...
    }

```
### Parameters

#### user
The address of the user claiming points
#### amount
The amount of points the user is claiming
#### v r s
The signature of the admin 
#### deadline
The signature deadline

# permitSwapToPaymentCoin
## ribbonVault.sol
### For swapping onchain points to reward token 
```javascript

function permitSwapToPaymentCoin(address user,uint pointToSwap,uint256 deadline,uint8 v,bytes32 r,bytes32 s)public {
    //...
    }

```
### Parameters

#### user
The address of the user swapping onchain points to reward token
#### amount
The amount of points the user is claiming
#### v ,r ,s
The signature of the admin 
#### deadline
The signature deadline






