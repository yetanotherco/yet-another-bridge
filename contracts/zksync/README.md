# zkSync Escrow

This project was initialized with [zksync-cli](https://github.com/matter-labs/zksync-cli).

## Project Layout

- `/src`: Contains source files, solidity smart contracts.
- `/scripts`: Scripts for contract deployment and interaction.
- `/tests`: Test files.
- `hardhat.config.ts`: Configuration settings.

## How to Use

- `make zksync-build`: Compiles contracts.
- `make zksync-deploy`: Deploys using script `/deploy/deploy.ts`.
- `make zksync-test`: Tests the contracts.

### Network Support

`hardhat.config.ts` comes with a list of networks to deploy and test contracts. Add more by adjusting the `networks` section in the `hardhat.config.ts`. To make a network the default, set the `defaultNetwork` to its name. You can also override the default using the `--network` option, like: `hardhat test --network dockerizedNode`.

### Local Tests

Running `npm run test` by default runs the [zkSync In-memory Node](https://era.zksync.io/docs/tools/testing/era-test-node.html) provided by the [@matterlabs/hardhat-zksync-node](https://era.zksync.io/docs/tools/hardhat/hardhat-zksync-node.html) tool.

Important: zkSync In-memory Node currently supports only the L2 node. If contracts also need L1, use another testing environment like Dockerized Node. Refer to [test documentation](https://era.zksync.io/docs/tools/testing/) for details.



## License

This project is under the [MIT](./LICENSE) license.