
deps: install-scarb install-starknet-foundry install-eth-foundry

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  2.4.1

install-starknet-foundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.12.0

install-eth-foundry:
	curl -L https://foundry.paradigm.xyz | bash && foundryup

solidity-clean:
	@cd ./contracts/solidity/ && forge clean

solidity-build: solidity-clean
	@cd ./contracts/solidity/ && forge build

solidity-test: solidity-clean
	@cd ./contracts/solidity/ && forge test

ethereum-deploy: solidity-clean
	@./contracts/solidity/deploy.sh

cairo-clean:
	@cd ./contracts/cairo/ && scarb clean

cairo-build: cairo-clean
	@cd ./contracts/cairo/ && scarb build

cairo-test: cairo-clean
	@cd ./contracts/cairo/ && snforge test

starknet-deploy: cairo-build
	@./contracts/cairo/deploy.sh