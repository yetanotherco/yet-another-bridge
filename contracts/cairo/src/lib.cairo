mod ERC20;
mod Escrow;
mod EscrowV2;

mod interfaces {
    mod IERC20;
    mod IEVMFactsRegistry;
}

mod mocks {
    mod mock_EVMFactsRegistry;
}

#[cfg(test)]
mod tests {
    mod test_escrow;

    mod utils {
        mod constants;
    }
}
