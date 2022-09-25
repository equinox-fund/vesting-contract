[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://github.com/prettier/prettier)

# Vesting contract

### Credits 📄

This is contract has been highly inspired from [@abdelhamidbakhta](https://github.com/abdelhamidbakhta/token-vesting-contracts). Thank you for your amazing work!

## Overview

Vesting contract who can release linearly (days) a token balance for whitelisted users.
Optionally revocable by the owner.

## Configuration

Rename `.env.example` to `.env` and add your private key for your favorite blockchain.

### hardhat.config.ts

We've already added public node urls for Binance Smart Chain and Polygon.
We recommend using Moralis to get a free node and deploy on Ethereum or Avalanche. Please see [here](https://docs.moralis.io/speedy-nodes/connecting-to-rpc-nodes/connect-to-eth-node).

## Contract configuration

Set up your contract configuration with `setup.json` located in `scripts` folder.

**Please make sure to complete setup.json before you run the deploy command**

```json
{
  "tokenContractAddress": "",
  "startDate": "2022-01-01T00:00:00.000Z",
  "durationInDays": 90,
  "slicePeriodInDays": 30
}
```

### tokenContractAddress

Contract address of the token we are doing the vesting for

### startDate

Date when the vesting start. **Do not confuse with the first release date!**

The first release date is the startDate + slicePeriodInDays. For this example, the first release date will be January 31, 2022 1:00 AM.

it should be using the DateTime Format. (YYY-MM-DDTHH:mm:ss.sssZ)

### durationInDays

The duration of the vesting period. For this example, the vesting will end on April 1, 2022 1:00 AM

### slicePeriodInDays

Define the interval in days when release happen.

For this example, there is 3 releases every 30 days.

For example, if a user has 900 vested tokens, every 30 days he will receive 300 tokens.

## Deploy your contract

```javascript
// Binance Smart chain
// mainnet
npm run deploy:bsc:mainnet
// testnet
npm run deploy:bsc:testnet

// ETHEREUM
// mainnet
npm run deploy:eth:mainnet
// testnet
npm run deploy:eth:testnet

// Avalanche
// mainnet
npm run deploy:avax:mainnet
// testnet
npm run deploy:avax:testnet

// Polygon
// mainnet
npm run deploy:matic:mainnet
// testnet
npm run deploy:matic:testnet


```

## Adding vesting entries

This vesting contract works with a whitelist (vesting entries), your users must be on the whitelist to access the vesting.

You must be calling the `addMultipleVestingEntry` from your favorite UI (Defender, Remix, ..) or custom script.

```solidty
function addMultipleVestingEntry(
  address[] calldata _users,
  uint256[] calldata _amounts
)
```

Example:

```solidity
addMultipleVestingEntry(['0x70A78123250635DD66b081D029B5e65F8c5EDB42'], [100]);
```

**Please note**:
If the user already owns a vesting entry, his vested token amount will be top-up.

**IMPORTANT**: The contract does not deal with token decimals, make sure to send correct decimals amount.

If your token contract is 18 decimals, the amount above should be `100000000000000000000`

## Tests

```shell
npm run test
```

## Etherscan verification

Make sure to enter your Etherscan API key in your `.env` file

copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network bscMainnet DEPLOYED_CONTRACT_ADDRESS
```

## Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).

## Security
This new contract is not officially audited and verified; however, we considered taking best security practices and used vetted libs like openzeppelin whenever possible. We tested our smart contract using the most actively developed related tools, namely Mythril and Slither, which reported zero security issues.

please contact security [at] equinox.fund if you believe you've found a security vulnerability.
