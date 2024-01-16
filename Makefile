deps: install-scarb install-starkli install-starknet-foundry install-ethereum-foundry update-submodules

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  2.4.1

install-starkli: 
	curl https://get.starkli.sh | sh && starkliup

install-starknet-foundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.12.0

install-ethereum-foundry:
	curl -L https://foundry.paradigm.xyz | bash && foundryup

update-submodules:
	git submodule update --init --recursive

ethereum-clean:
	@cd ./contracts/solidity/ && forge clean

ethereum-build: ethereum-clean
	@cd ./contracts/solidity/ && forge build

ethereum-test: ethereum-clean
	@cd ./contracts/solidity/ && forge test

ethereum-deploy: ethereum-build
	@./contracts/solidity/deploy.sh

ethereum-upgrade: ethereum-build
	@./contracts/solidity/upgrade.sh

ethereum-set-escrow:
	@./contracts/solidity/set_escrow.sh

ethereum-set-withdraw-selector:
	@./contracts/solidity/set_withdraw_selector.sh

starknet-clean:
	@cd ./contracts/cairo/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/cairo/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/cairo/ && snforge test

starknet-deploy: starknet-build
	@./contracts/cairo/deploy.sh

starknet-deploy-and-connect: starknet-build
	@$(MAKE) starknet-deploy
	@$(MAKE) ethereum-set-escrow
	@$(MAKE) ethereum-set-withdraw-selector
