// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {RevenueClaimer} from "src/RevenueClaimer.sol";

contract MockRevenueManager {
    address public protocolRecipient;
    uint256 public payout; // amount of ETH to send on protocolClaim

    constructor(address _recipient) {
        protocolRecipient = _recipient;
    }

    function setPayout(uint256 amount) external {
        payout = amount;
    }

    function protocolClaim() external {
        require(protocolRecipient != address(0), "no recip");
        uint256 amount = payout;
        payout = 0;
        if (amount > 0) {
            (bool ok, ) = protocolRecipient.call{value: amount}("");
            require(ok, "send fail");
        }
    }

    receive() external payable {}
}

contract RevenueClaimerTest is Test {
    // Mirror event signature for expectEmit
    event Claimed(address indexed manager, uint256 amount);

    RevenueClaimer public claimer;
    MockRevenueManager public manager;
    address public owner = address(this);
    address public alice = address(0xA11CE);

    uint256 constant THRESHOLD = 0.01 ether;

    function setUp() public {
        claimer = new RevenueClaimer(owner);
        manager = new MockRevenueManager(address(claimer));
    }

    function test_RevertWhen_NotRecipient() public {
        // Point manager to someone else
        manager = new MockRevenueManager(alice);
        vm.expectRevert(bytes("Not recipient"));
        claimer.claimIfThreshold(address(manager));
    }

    function test_RevertWhen_BelowThreshold() public {
        // Set payout just below threshold
        manager.setPayout(THRESHOLD - 1);
        vm.deal(address(manager), THRESHOLD - 1);
        vm.expectRevert(bytes("Below threshold"));
        claimer.claimIfThreshold(address(manager));
    }

    function test_Succeeds_When_AtLeastThreshold() public {
        uint256 amount = THRESHOLD;
        manager.setPayout(amount);
        vm.deal(address(manager), amount);

        uint256 balBefore = address(claimer).balance;
        vm.expectEmit(true, false, false, true);
        emit Claimed(address(manager), amount);
        claimer.claimIfThreshold(address(manager));
        assertEq(
            address(claimer).balance,
            balBefore + amount,
            "balance increased"
        );
    }

    function test_Succeeds_When_AboveThreshold() public {
        uint256 amount = THRESHOLD + 1 ether;
        manager.setPayout(amount);
        vm.deal(address(manager), amount);
        claimer.claimIfThreshold(address(manager));
        assertEq(address(claimer).balance, amount);
    }
}
