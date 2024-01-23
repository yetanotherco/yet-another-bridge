mod ERC20;
mod escrow;

mod interfaces {
    mod IERC20;
    mod IEVMFactsRegistry;
}

mod mocks {
    mod mock_EVMFactsRegistry;
    mod mock_Escrow_changed_functions;
    mod mock_Escrow_lessVars;
    mod mock_Escrow_moreVars_after;
    mod mock_Escrow_moreVars_before;
    mod mock_Escrow_replaceVars;
    mod mock_Escrow_reorgVars;
    mod mock_Escrow_oldVars;
    mod mock_Escrow_replacePlusOldVars;
}

#[cfg(test)]
mod tests {
    mod test_escrow;
    mod test_escrow_storage;

    mod utils {
        mod constants;
    }
}
