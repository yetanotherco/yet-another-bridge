mod ERC20;
mod escrow;

mod interfaces {
    mod IERC20;
    mod IEVMFactsRegistry;
}

mod mocks {
    mod mock_EVMFactsRegistry;
    mod mock_Escrow_changed_functions;
    mod mock_pausableEscrow;
}

#[cfg(test)]
mod tests {
    mod test_escrow_allowance;
    mod test_escrow_pause;
    mod test_escrow_upgrade;
    mod test_escrow_ownable;
    mod test_escrow_claim;

    mod utils {
        mod constants;
    }
}
