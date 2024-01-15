mod ERC20;
mod Escrow;

mod interfaces {
    mod IERC20;
    mod IEVMFactsRegistry;
}

mod mocks {
    mod mock_EVMFactsRegistry;
    mod mock_EscrowV2;

}

#[cfg(test)]
mod tests {
    mod test_escrow;

    mod utils {
        mod constants;
    }
}
