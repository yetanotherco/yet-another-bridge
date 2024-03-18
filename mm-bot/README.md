# Market Maker Bot
Market Maker Bot is a bot that provides liquidity to the Yet Another Bridge (YAB).

# Prerequisites
- Python v3.10 or higher
- pip
- Postgres (Native or Docker)

# Setup
## Installation

```bash
pip install -r requirements.txt
```
### Virtual Environment
If you want to use a virtual environment, you can use the following command:

```bash
make create_python_venv
```
To run the virtual environment, you can use the following command:

```bash
source venv/bin/activate
```

## Environment Variables
This API uses environment variables to configure the application. You can create a `.env` file in the root of the project to set the environment variables.

To create your own `.env` file run the following command:

```bash
make create_env
```

The following environment variables are used:

    ENVIRONMENT=<dev|prod>
    ETH_RPC_URL=<ethereum_rpc_url>
    STARKNET_RPC=<starknet_rpc_url>
    ETH_FALLBACK_RPC_URL=<ethereum_fallback_rpc_url>
    SN_FALLBACK_RPC_URL=<starknet_fallback_rpc_url>
    ETH_CONTRACT_ADDR=<ethereum_contract_address>
    SN_CONTRACT_ADDR=<starknet_contract_address>
    ETH_PRIVATE_KEY=<ethereum_private_key>
    SN_WALLET_ADDR=<starknet_wallet_address>
    SN_PRIVATE_KEY=<starknet_private_key>
    HERODOTUS_API_KEY=<herodotus_api_key>
    POSTGRES_HOST=<postgres_host>
    POSTGRES_USER=<postgres_user>
    POSTGRES_PASSWORD=<postgres_password>
    POSTGRES_DB=<postgres_db>
    LOGGING_LEVEL=<DEBUG|INFO|WARNING|ERROR|CRITICAL>
    LOGGING_DIR=<logging_directory to save the logs in prod mode>
    PAYMENT_CLAIMER=<herodotus|ethereum>


There is a example file called `.env.example` in the root of the project. 

## Database Setup
### Create Database Container
This Bot uses a Postgres database. You can either install Postgres natively or use Docker (recommended for development environment). 
If you use Docker, you can use the following command to start a Postgres container:
```bash
make create_db container=<container> user=<user> password=<pwd> database=<db_name>
```
    Where:
    - container:    the name of the docker container. If not provided, the default value is 'postgres'
    - user:         the user to create. If not provided, the default value is 'user'
    - password:     the password for the user. If not provided, the default value is '123123123'
    - database:     the name of the database to create. If not provided, the default value is 'mm-bot'

This container will have a database called `<database>`, by default it is `mm-bot`.

### Run Database Container
If you want to run or re-run the database container, you can use the following command:
```bash
make run_db container=<container>
```
    Where:
    - container:    the name of the docker container. If not provided, the default value is 'postgres'

### Stop Database Container
If you want to stop the database container, you can use the following command:
```bash
make stop_db container=<container>
```
    Where:
    - container:    the name of the docker container. If not provided, the default value is 'postgres'

### Database Population
To create the tables, you can use the following command:
```bash
TODO
```
You must run schema.sql into the database to create the tables. You can use pgAdmin or any other tool to run the script.

# Development
To start the Bot, you can use the following command:

```bash
python3 src/main.py
```

# Test [TODO]
To run the tests, you can use the following command:

```bash

```
