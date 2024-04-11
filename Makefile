### SETUP ###

deps: install-scarb install-starkli install-starknet-foundry install-ethereum-foundry install-zksync

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v  2.4.1

install-starkli: 
	curl https://get.starkli.sh | sh && starkliup

install-starknet-foundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh -s -- -v 0.12.0
	snfoundryup

install-ethereum-foundry:
	curl -L https://foundry.paradigm.xyz | bash && foundryup

install-zksync:
	cd ./contracts/zksync/ && yarn install


### ETHEREUM ###

ethereum-clean:
	@cd ./contracts/ethereum/ && forge clean

ethereum-build: ethereum-clean
	@cd ./contracts/ethereum/ && forge build

ethereum-test: ethereum-clean
	@cd ./contracts/ethereum/ && forge test

ethereum-test-gas-report: ethereum-clean
	@cd ./contracts/ethereum/ && forge test --gas-report

ethereum-deploy: ethereum-build
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/deploy.sh

ethereum-upgrade: ethereum-build
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/upgrade.sh

ethereum-set-escrow:
	@. ./contracts/ethereum/.env && . ./contracts/ethereum/set_starknet_escrow.sh


### STARKNET ###

starknet-clean:
	@cd ./contracts/starknet/ && scarb clean

starknet-build: starknet-clean
	@cd ./contracts/starknet/ && scarb build

starknet-test: starknet-clean
	@cd ./contracts/starknet/ && snforge test

starknet-deploy: starknet-build
	@. ./contracts/starknet/.env && . ./contracts/starknet/scripts/deploy.sh

starknet-connect:
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env && \
	. ./contracts/ethereum/set_starknet_escrow.sh

starknet-deploy-and-connect: starknet-build
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env && \
	. ./contracts/starknet/scripts/deploy.sh && \
	. ./contracts/ethereum/set_starknet_escrow.sh

starknet-upgrade: starknet-build
	@. ./contracts/starknet/.env && . ./contracts/starknet/scripts/upgrade.sh

starknet-pause:
	@. ./contracts/starknet/.env && . ./contracts/starknet/scripts/change_pause_state.sh pause

starknet-unpause:
	@. ./contracts/starknet/.env && . ./contracts/starknet/scripts/change_pause_state.sh unpause


### ZKSYNC ###

zksync-clean:
	@cd ./contracts/zksync/ && yarn clean

zksync-build: zksync-clean
	@cd ./contracts/zksync/ && yarn compile

zksync-deploy: zksync-build
	@. ./contracts/zksync/.env && . ./contracts/zksync/deploy.sh

zksync-connect:
	@. ./contracts/ethereum/.env && . ./contracts/zksync/.env && \
	. ./contracts/ethereum/set_zksync_escrow.sh

zksync-deploy-and-connect: zksync-build
	@. ./contracts/ethereum/.env && . ./contracts/zksync/.env && \
	. ./contracts/zksync/deploy.sh && \
	. ./contracts/ethereum/set_zksync_escrow.sh

zksync-test: zksync-build
	@cd ./contracts/zksync/ && yarn test

zksync-test-in-memory: zksync-build
	@cd ./contracts/zksync/ && yarn test-in-memory

#wip CI:
zksync-test-integration-ci:
	@. ./.github/workflows/zksync-scripts/ci.env.test && \
	. ./contracts/ethereum/deploy.sh && \
	. ./contracts/zksync/deploy.sh && \
	. ./contracts/ethereum/set_zksync_escrow.sh && \
	. ./contracts/zksync/test/set_order.sh && \
	. ./contracts/zksync/test/transfer.sh && \
	. ./contracts/zksync/test/claim_payment.sh && \
	. ./.github/workflows/zksync-scripts/assert.sh

#old version:
zksync-test-integration-local:
	@make ethereum-build && make zksync-build && \
	. ./contracts/ethereum/test/.env.test && . ./contracts/zksync/test/.env.test && \
	. ./contracts/ethereum/deploy.sh && \
	. ./contracts/zksync/deploy.sh && \
	. ./contracts/ethereum/set_zksync_escrow.sh && \
	. ./contracts/zksync/test/set_order.sh && \
	. ./contracts/zksync/test/transfer.sh && \
	. ./contracts/zksync/test/claim_payment.sh && \
	. ./.github/workflows/zksync-scripts/assert.sh

# zksync-upgrade: WIP


### MULTI ###

ethereum-and-zksync-deploy:
	@. ./contracts/ethereum/.env && \
	. ./contracts/zksync/.env && \
	make ethereum-build && \
	make zksync-build && \
	. ./contracts/ethereum/deploy.sh && \
	. ./contracts/zksync/deploy.sh && \
	. ./contracts/ethereum/set_zksync_escrow.sh && \
	. ./contracts/utils/display_info.sh

ethereum-and-starknet-deploy:
	@. ./contracts/ethereum/.env && \
	. ./contracts/starknet/.env && \
	make ethereum-build && \
	make starknet-build && \
	. ./contracts/ethereum/deploy.sh && \
	. ./contracts/starknet/scripts/deploy.sh && \
	. ./contracts/ethereum/set_starknet_escrow.sh && \
	. ./contracts/utils/display_info.sh

deploy-all:
	@. ./contracts/ethereum/.env && . ./contracts/starknet/.env && . ./contracts/zksync/.env && \
	make ethereum-build && \
	. ./contracts/ethereum/deploy.sh && \
	make starknet-build && \
	. ./contracts/starknet/scripts/deploy.sh && \
	. ./contracts/ethereum/set_starknet_escrow.sh && \
	. ./contracts/utils/display_info.sh && \
	make zksync-build && \
	. ./contracts/zksync/deploy.sh && \
	. ./contracts/ethereum/set_zksync_escrow.sh

test: 
	make starknet-test
	make ethereum-test
	make zksync-test
