mod EscrowConstants {
    use starknet::{EthAddress, ContractAddress, contract_address_const};

    fn USER() -> ContractAddress {
        contract_address_const::<'USER'>()
    }

    fn OWNER() -> ContractAddress {
        contract_address_const::<'OWNER'>()
    }

    fn MM_STARKNET() -> ContractAddress {
        contract_address_const::<'HERODOTUS_FACTS_REGISTRY'>()
    }

    fn MM_ETHEREUM() -> EthAddress {
        50.try_into().unwrap()
    }

    fn ETH_TRANSFER_CONTRACT() -> EthAddress {
        69.try_into().unwrap()
    }

    fn ETH_USER() -> EthAddress {
        99.try_into().unwrap()
    }
}
