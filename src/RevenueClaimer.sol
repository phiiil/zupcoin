// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IRevenueManagerMinimal {
    function protocolRecipient() external view returns (address);
    function protocolClaim() external;
}

// Minimal Across SpokePool interface (V2/V3-style deposit)
interface IAcrossSpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        int64 relayerFeePct,
        uint32 quoteTimestamp,
        bytes calldata message
    ) external payable;
}

/**
 * @title RevenueClaimer
 * @notice Claims protocol revenue from a Flaunch RevenueManager only when the amount is >= threshold,
 *         and can bridge ETH via Across to a destination chain (e.g., L1 Ethereum).
 * @dev This contract must be set as the protocolRecipient on the target RevenueManager.
 */
contract RevenueClaimer is Ownable, ReentrancyGuard {
    uint256 public constant MIN_THRESHOLD_WEI = 0.01 ether;

    // Across configuration: SpokePool on source chain (e.g., Base)
    address public acrossSpokePool;

    event Claimed(address indexed manager, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event AcrossSpokePoolUpdated(address indexed spokePool);
    event Bridged(
        address indexed recipient,
        uint256 amount,
        uint256 destinationChainId
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Owner sets the Across SpokePool address for the current chain (e.g., Base).
     */
    function setAcrossSpokePool(address spokePool) external onlyOwner {
        require(spokePool != address(0), "spoke=0");
        acrossSpokePool = spokePool;
        emit AcrossSpokePoolUpdated(spokePool);
    }

    /**
     * @notice Claims revenue from a RevenueManager if the amount to be received is >= MIN_THRESHOLD_WEI.
     * @dev Reverts if this contract is not the protocolRecipient for the manager.
     * @param manager Address of the RevenueManager
     */
    function claimIfThreshold(address manager) external nonReentrant onlyOwner {
        address self = address(this);
        if (IRevenueManagerMinimal(manager).protocolRecipient() != self) {
            revert("Not recipient");
        }

        uint256 balanceBefore = self.balance;
        IRevenueManagerMinimal(manager).protocolClaim();
        uint256 received = self.balance - balanceBefore;
        if (received < MIN_THRESHOLD_WEI) revert("Below threshold");

        emit Claimed(manager, received);
    }

    /**
     * @notice Bridge a specified amount of ETH to a destination chain via Across SpokePool.
     * @dev For ETH bridging, originToken is set to address(0). Destination chain ID should match target chain (e.g., 1 for Ethereum L1).
     *      relayerFeePct and quoteTimestamp should be set per Across quoting guidance.
     * Docs: https://docs.across.to/
     * @param recipient Recipient on the destination chain
     * @param amount Amount of ETH to bridge (must be <= contract balance)
     * @param destinationChainId Destination chain id (e.g., 1 for Ethereum mainnet)
     * @param relayerFeePct Relayer fee in Across format (int64)
     * @param quoteTimestamp Quote timestamp used when computing relayerFeePct
     * @param message Optional message payload for Across
     */
    function bridgeETHViaAcross(
        address recipient,
        uint256 amount,
        uint256 destinationChainId,
        int64 relayerFeePct,
        uint32 quoteTimestamp,
        bytes calldata message
    ) external nonReentrant onlyOwner {
        require(acrossSpokePool != address(0), "spoke not set");
        require(recipient != address(0), "recipient=0");
        require(amount >= MIN_THRESHOLD_WEI, "amount<threshold");
        require(amount <= address(this).balance, "insufficient");

        IAcrossSpokePool(acrossSpokePool).deposit{value: amount}(
            recipient,
            address(0),
            amount,
            destinationChainId,
            relayerFeePct,
            quoteTimestamp,
            message
        );

        emit Bridged(recipient, amount, destinationChainId);
    }

    /**
     * @notice Withdraws ETH held by this contract to a recipient.
     * @param to The recipient address
     * @param amount The amount to withdraw
     */
    function withdraw(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "to=0");
        require(amount <= address(this).balance, "insufficient");
        (bool ok, ) = to.call{value: amount}(new bytes(0));
        require(ok, "transfer failed");
        emit Withdrawn(to, amount);
    }

    receive() external payable {}
}
