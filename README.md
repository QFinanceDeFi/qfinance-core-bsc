# QFinance Core

### Trustless, decentralized investment pools on Ethereum

_Available live on Binance Smart Chain. Use https://qfihub.com to get started or to read more about how it works._

## Getting Started (Local)

You must install `nodeJS`

This guide uses `yarn` but you can use `npm` if you prefer.

### Install Dependencies

```bash
yarn
```

### Setup Environment

1. Use Ganache CLI and a public Binance RPC url to fork the mainnet.
2. Recommended to create a new Metamask wallet (not connected to any mainnet funds as you will be using your seed.)
3. Create a `secrets.json` file in the root. Add the following value:
   - mnemonic: [mnemonic phrase from Metamask]

### Run Tests

1. Run the Ganache CLI first - we will run it by forking the Kovan Ethereum testnet so we can interact with it in its current state:

```bash
ganache-cli -f [Binance RPC url] -m "seed phrase"
```

2. Run tests:

```bash
truffle test --network development
```