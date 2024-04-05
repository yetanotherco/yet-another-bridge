# Market Maker Bot
Market Maker Bot is a bot that provides liquidity to the Yet Another Bridge (YAB).

## Prerequisites
- [Python v3.10](https://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installation/)
- Postgres ([Local](https://www.postgresql.org/) or [Docker](https://hub.docker.com/_/postgres))
- [pyenv](https://github.com/pyenv/pyenv) (Optional)

## Setup
### Installation
#### Virtual Environment
Create the virtual environment using the following command:

```bash
make create_python_venv
```
To run the virtual environment, you can use the following command:

```bash
source venv/bin/activate
```

#### Dependencies
To install the dependencies, you can use the following command:

```bash
make deps
```

### Database Setup
#### Create Database Container
This Bot uses a Postgres database. You can either install Postgres locally or use Docker (recommended for development environment). 

If you use Docker, you can use the following command to start a Postgres container:
```bash
make create_db container=<container> user=<user> password=<pwd> database=<db_name>
```

| Variable  | Description                                                                           |
|-----------|---------------------------------------------------------------------------------------|
| container | The name of the docker container. If not provided, the default value is `mm-bot`      |
| user      | The user to create. If not provided, the default value is `user`                      |
| password  | The password for the user. If not provided, the default value is `123123123`          |
| database  | The name of the database to create. If not provided, the default value is `mm-bot-db` |

This container will have a database called `<db_name>`, by default it is `mm-bot-db`.

#### Run Database Container
If you want to run or re-run the database container, you can use the following command:
```bash
make start_db container=<container>
```

| Variable  | Description                                                                           |
|-----------|---------------------------------------------------------------------------------------|
| container | The name of the docker container. If not provided, the default value is `mm-bot`      |

#### Stop Database Container
If you want to stop the database container, you can use the following command:
```bash
make stop_db container=<container>
```

| Variable  | Description                                                                           |
|-----------|---------------------------------------------------------------------------------------|
| container | The name of the docker container. If not provided, the default value is `mm-bot`      |

### Environment Variables
This API uses environment variables to configure the application. You can create a `.env` file in the root of the project to set the environment variables.

To create your own `.env` file run the following command:

```bash
make create_env
```

The following table describes each environment variable:

| Variable                  | Description                                                                                                       |
|---------------------------|-------------------------------------------------------------------------------------------------------------------|
| ENVIRONMENT               | The environment of the application. It can be `dev` or `prod`                                                     |
| ETHEREUM_CHAIN_ID         | The chain ID of the Ethereum network. It can be `1` for Mainnet, 11155111 for Sepolia                             |
| STARKNET_CHAIN_ID         | The chain ID of the Starknet network. It can be `0x534e5f4d41494e` for Mainnet, `0x534e5f5345504f4c4941` for Sepolia                |
| ZKSYNC_CHAIN_ID           | The chain ID of the ZKSync network. I can be `324` for Mainnet, `300` for sepolia |
| ETHEREUM_RPC              | The URL of the Ethereum RPC. You can get one at [Blast](https://blastapi.io/) or [Infure](https://www.infura.io/) |
| STARKNET_RPC              | The URL of the Starknet RPC. You can get one at [Blast](https://blastapi.io/) or [Infure](https://www.infura.io/) |
| ZKSYNC_RPC                | The URL of the ZkSync RPC. You can get one at [Blast](https://blastapi.io/)                                       |
| ETH_FALLBACK_RPC_URL      | The URL of the Ethereum RPC fallback                                                                              |
| SN_FALLBACK_RPC_URL       | The URL of the Starknet RPC fallback                                                                              |
| ZKSYNC_FALLBACK_RPC_URL   | The URL of the ZkSync RPC fallback                                                                                | 
| ETHEREUM_CONTRACT_ADDRESS | The address of the Payment Registry                                                                               |
| STARKNET_CONTRACT_ADDRESS | The address of the Starknet Escrow                                                                                |
| ZKS_CONTRACT_ADDRESS      | The address of the ZkSync Escrow                                                                                  |
| ETHEREUM_PRIVATE_KEY      | The private key of Market Maker on Ethereum                                                                       |
| STARKNET_WALLET_ADDRESS   | The wallet address of Market Maker on Starknet                                                                    |
| STARKNET_PRIVATE_KEY      | The private key of Market Maker on Starknet                                                                       |
| HERODOTUS_API_KEY         | (Optional) The API key of Herodotus. Needed if using herodotus payment claimer                                    |
| POSTGRES_HOST             | The host of the Postgres database                                                                                 |
| POSTGRES_USER             | The user of the Postgres database                                                                                 |
| POSTGRES_PASSWORD         | The password of the Postgres database                                                                             |
| POSTGRES_DATABASE         | The name of the Postgres database                                                                                 |
| LOGGING_LEVEL             | The level of logging. It can be `DEBUG`, `INFO`, `WARNING`, `ERROR`, or `CRITICAL`                                |
| LOGGING_DIRECTORY         | The directory to save the logs in prod `mode`. Only needed in `prod` mode                                         |
| PAYMENT_CLAIMER           | The payment claimer. It can be `herodotus` or `ethereum`                                                          |

There is an example file called `.env.example` in the root of the project. 

#### Database Population
To create the tables, you can use the following command:
```bash
TODO
```
You must run schema.sql into the database to create the tables. You can use pgAdmin or any other tool to run the script.

## Development
To start the Bot, you can use the following command:

```bash
make run
```

## Test [TODO]
To run the tests, you can use the following command:

```bash

```
