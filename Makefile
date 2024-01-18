deps: install-scarb install-starkli install-starknet-foundry install-ethereum-foundry

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  2.4.1

install-starkli: 
	curl https://get.starkli.sh | sh && starkliup

install-starknet-foundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.12.0

install-ethereum-foundry:
	curl -L https://foundry.paradigm.xyz | bash && foundryup

ethereum-clean:
	@cd ./contracts/solidity/ && forge clean

ethereum-build: ethereum-clean
	@cd ./contracts/solidity/ && forge build

ethereum-test: ethereum-clean
	@cd ./contracts/solidity/ && forge test

ethereum-deploy: ethereum-clean
	@./contracts/solidity/deploy.sh

ESCROW_CONTRACT_ADDRESS=
ethereum-set-escrow:
	@(source ./contracts/solidity/.env; export ESCROW_CONTRACT_ADDRESS=$(ESCROW_CONTRACT_ADDRESS) ; . ./contracts/solidity/set_escrow.sh)

WITHDRAW_NAME?="withdraw"
ETH_CONTRACT_ADDR=
ethereum-set-withdraw-selector:
	@(source ./contracts/solidity/.env; export WITHDRAW_NAME=$(WITHDRAW_NAME); export ETH_CONTRACT_ADDRESS=$(ETH_CONTRACT_ADDR) ; . ./contracts/solidity/set_withdraw_selector.sh)

starknet-clean:
	@cd ./contracts/cairo/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/cairo/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/cairo/ && snforge test

starknet-deploy: starknet-build
	@source ./contracts/cairo/.env && . ./contracts/cairo/deploy.sh

starknet-upgrade: starknet-build
	@./contracts/cairo/upgrade.sh

.ONESHELL:
starknet-deploy-and-connect:
	@source ./contracts/cairo/.env && . ./contracts/cairo/deploy.sh
	@source ./contracts/solidity/.env && . ./contracts/solidity/set_escrow.sh
	@source ./contracts/solidity/.env && . ./contracts/solidity/set_withdraw_selector.sh
