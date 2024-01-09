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


Command := $(firstword $(MAKECMDGOALS))
PARAM := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ethereum-set-escrow:
ifneq ($(PARAM),)
	@./contracts/solidity/set_escrow.sh $(PARAM)
else
	@echo "Error: New Escrow address nedded"
	@echo "Example of usage:"
	@echo "make ethereum-set-escrow 0x01234..."
endif
%::
	@true


Command := $(firstword $(MAKECMDGOALS))
PARAM := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
ethereum-set-withdraw-selector:
ifneq ($(PARAM),)
	@./contracts/solidity/set_withdraw_selector.sh $(PARAM)
else
	@echo "Error: New withdraw selector nedded"
	@echo "Example of usage:"
	@echo "make ethereum-set-withdraw-selector 0x01234..."
endif
%::
	@true


starknet-clean:
	@cd ./contracts/cairo/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/cairo/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/cairo/ && snforge test

starknet-deploy: starknet-build
	@./contracts/cairo/deploy.sh