// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2 as console} from "forge-std/Script.sol";
import {IFlaunchZap} from "src/interfaces/IFlaunchZap.sol";
import {RevenueManagerTypes} from "src/types/RevenueManagerTypes.sol";

/// @notice Script to flaunch a token called ZUP using the Flaunch Zap, following docs.
/// Docs reference: https://docs.flaunch.gg/implementation#id-3.-flaunch-tokens-directly-to-manager
contract FlaunchZUPScript is Script {
    // Base Sepolia RevenueManager implementation from docs
    address internal constant DEFAULT_BASE_SEPOLIA_REVENUE_MANAGER_IMPL =
        0x1216c723853Dac0449C01D01D6e529d751D9c0c8;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address zap = vm.envAddress("FLAUNCH_ZAP");

        // Optional: specify a manager implementation to deploy/initialize; default to Base Sepolia RevenueManager.
        address managerImpl = vm.envOr(
            "MANAGER_IMPL",
            DEFAULT_BASE_SEPOLIA_REVENUE_MANAGER_IMPL
        );

        // If not provided, default the protocolRecipient to the deployer address
        address protocolRecipient = vm.envOr("PROTOCOL_RECIPIENT", address(0));
        if (protocolRecipient == address(0)) {
            protocolRecipient = vm.addr(pk);
        }
        uint256 protocolFeeBps = vm.envOr("PROTOCOL_FEE_BPS", uint256(1000)); // default 10%

        // Token params
        string memory name = vm.envOr("TOKEN_NAME", string("ZUP"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("ZUP"));
        address creator = vm.envOr("CREATOR", vm.addr(pk));

        console.log("Zap:", zap);
        console.log("Creator:", creator);
        console.log("Token:", name, symbol);
        console.log("ManagerImpl:", managerImpl);
        console.log("ProtocolRecipient:", protocolRecipient);
        console.log("ProtocolFeeBps:", protocolFeeBps);

        IFlaunchZap.FlaunchParams memory fParams = IFlaunchZap.FlaunchParams({
            creator: creator,
            name: name,
            symbol: symbol
        });

        IFlaunchZap.TreasuryManagerParams memory tParams;
        if (managerImpl != address(0)) {
            RevenueManagerTypes.InitializeParams
                memory init = RevenueManagerTypes.InitializeParams({
                    protocolRecipient: payable(protocolRecipient),
                    protocolFee: protocolFeeBps
                });
            tParams = IFlaunchZap.TreasuryManagerParams({
                manager: managerImpl,
                initializeData: abi.encode(init),
                depositData: abi.encode("")
            });
        } else {
            // No manager deployment; pass-through params
            tParams = IFlaunchZap.TreasuryManagerParams({
                manager: address(0),
                initializeData: bytes(""),
                depositData: bytes("")
            });
        }

        vm.startBroadcast(pk);
        (address memecoin, , address deployedManager) = IFlaunchZap(zap)
            .flaunch({
                _flaunchParams: fParams,
                _treasuryManagerParams: tParams
            });
        vm.stopBroadcast();

        console.log("Memecoin:", memecoin);
        console.log("DeployedManager:", deployedManager);
    }
}
