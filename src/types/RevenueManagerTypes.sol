// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library RevenueManagerTypes {
    /// @dev Matches the InitializeParams used by RevenueManager per docs
    struct InitializeParams {
        address payable protocolRecipient;
        uint256 protocolFee; // in bps (e.g., 1000 = 10%)
    }
}
