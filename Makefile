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
	@cd ./contracts/solidity/ && forge clean

ethereum-build: ethereum-clean
	@cd ./contracts/solidity/ && forge build

ethereum-test: ethereum-clean
	@cd ./contracts/solidity/ && forge test

ethereum-deploy: ethereum-build
	@. ./contracts/solidity/.env && . ./contracts/solidity/deploy.sh

ethereum-upgrade: ethereum-build
	@. ./contracts/solidity/.env && . ./contracts/solidity/upgrade.sh

ethereum-set-escrow:
	@. ./contracts/solidity/.env && . ./contracts/solidity/set_escrow.sh

ethereum-set-claim-payment-selector:
	@. ./contracts/solidity/.env && . ./contracts/cairo/.env && . ./contracts/solidity/set_claim_payment_selector.sh

starknet-clean:
	@cd ./contracts/cairo/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/cairo/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/cairo/ && snforge test

starknet-deploy: starknet-build
	@. ./contracts/cairo/.env && . ./contracts/cairo/deploy.sh

starknet-upgrade: starknet-build
	@. ./contracts/cairo/.env && . ./contracts/cairo/upgrade.sh

starknet-pause:
	@. ./contracts/cairo/.env && ./contracts/cairo/change_pause_state.sh pause

starknet-unpause:
	@. ./contracts/cairo/.env && ./contracts/cairo/change_pause_state.sh unpause

test: 
	make starknet-test
	make ethereum-test

malo:
	@. ./contracts/solidity/.env && . ./contracts/cairo/.env && . ./contracts/solidity/malicious.sh


.ONESHELL:
starknet-deploy-and-connect: starknet-build
	@. ./contracts/solidity/.env && . ./contracts/cairo/.env
	@. ./contracts/cairo/deploy.sh
	@. ./contracts/solidity/set_escrow.sh
	@. ./contracts/solidity/set_claim_payment_selector.sh

.ONESHELL:
deploy-all:
	@. ./contracts/solidity/.env && . ./contracts/cairo/.env
	@make ethereum-build
	@. ./contracts/solidity/deploy.sh
	@make starknet-build
	@. ./contracts/cairo/deploy.sh
	@. ./contracts/solidity/set_escrow.sh
	@. ./contracts/solidity/set_claim_payment_selector.sh
	@. ./contracts/utils/display_info.sh
