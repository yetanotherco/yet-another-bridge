deps: install-scarb install-starkli install-starknet-foundry install-ethereum-foundry

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  2.4.1

install-starkli: 
	curl https://get.starkli.sh | sh && starkliup

install-starknet-foundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.12.0
	snfoundryup

install-ethereum-foundry:
	curl -L https://foundry.paradigm.xyz | bash && foundryup

ethereum-clean:
	@cd ./contracts/ethereum/ && forge clean

ethereum-build: ethereum-clean
	@cd ./contracts/ethereum/ && forge build

ethereum-test: ethereum-clean
	@cd ./contracts/ethereum/ && forge test

ethereum-deploy: ethereum-build
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/deploy.sh

ethereum-upgrade: ethereum-build
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/upgrade.sh

ethereum-set-escrow:
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/set_escrow.sh

ethereum-set-claim-payment-selector:
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env && . ./contracts/ethereum/set_claim_payment_selector.sh

starknet-clean:
	@cd ./contracts/starknet/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/starknet/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/starknet/ && snforge test

starknet-deploy: starknet-build
	@. ./contracts/starknet/.env && . ./contracts/starknet/deploy.sh

starknet-upgrade: starknet-build
	@. ./contracts/starknet/.env && . ./contracts/starknet/upgrade.sh

starknet-pause:
	@. ./contracts/starknet/.env && ./contracts/starknet/change_pause_state.sh pause

starknet-unpause:
	@. ./contracts/starknet/.env && ./contracts/starknet/change_pause_state.sh unpause

test: 
	make starknet-test
	make ethereum-test

.ONESHELL:
starknet-deploy-and-connect: starknet-build
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env
	@. ./contracts/starknet/deploy.sh
	@. ./contracts/ethereum/set_escrow.sh
	@. ./contracts/ethereum/set_claim_payment_selector.sh

.ONESHELL:
deploy-all:
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env
	@make ethereum-build
	@. ./contracts/ethereum/deploy.sh
	@make starknet-build
	@. ./contracts/starknet/deploy.sh
	@. ./contracts/ethereum/set_escrow.sh
	@. ./contracts/ethereum/set_claim_payment_selector.sh
	@. ./contracts/utils/display_info.sh
