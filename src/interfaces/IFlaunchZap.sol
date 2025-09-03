// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal interface for Flaunch Zap based on public docs.
/// Docs: https://docs.flaunch.gg/implementation#id-3.-flaunch-tokens-directly-to-manager
interface IFlaunchZap {
    struct FlaunchParams {
        address creator;
        string name;
        string symbol;
    }

    struct TreasuryManagerParams {
        address manager;
        bytes initializeData;
        bytes depositData;
    }

    /// @notice Flaunch a new token and optionally deploy/initialize a Treasury Manager.
    function flaunch(
        FlaunchParams calldata _flaunchParams,
        TreasuryManagerParams calldata _treasuryManagerParams
    )
        external
        returns (
            address memecoin_,
            address placeholder_,
            address deployedManager_
        );
}
