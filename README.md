## About
Ribbon Protocol is a universal health coverage rewards and loyalty platform that aims to modify health and wellness behavior through incentivization and rewardable tasks.
The Ribbon App intertwines Universal Basic Income with Universal Health Coverage, utilizing World ID users health & socioeconomic data to enhance global well-being. 
The protocol rewards users for activities that help assess their wellness and socioeconomic needs, while linking them to equitable UBI and personalized services.
Rewards and Incentives are distributed in points and WLD tokens, on the Optimism Mainnet network which is a Layer 2 network of the Ethereum blockchain.


## Core contract and in scope for Audit:
1. **Points** points is an ERC20 token which is been claimed by converting the virtual points offchain and claiming it on chain with the Vault contract, Points contract
 also has a function which is used to create vaults 
2. **RibbonVault** RibbonVault is a vault contract that is created from points contract , in this contract point and worldcoin token are been deposited in it and  users 
claim their point and swap it to worldcoin at a specified rate

## Actors
These are roles of everyone on the Ribbon protocol

### Users
This users answer questioniare offchain and accumulate virtual points offchain and they can claim this point onchain , they are able to swap their points claimed offchain 
to worldcoin at a specified rate with the permission of the admin

### admin
This is the address that can sign some parameters offchain and pass it to the users which can be used as verification to claim points or to swap points to worldcoin

## Compatibilities

Ribbon protocol is compatible with the following:

1. Any ERC20 token

Its not compatible with:

1. Any network which is not EVM compatible
2. Any token standard other than ERC20
3. Ether (ETH)

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