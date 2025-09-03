## Zup

Zup is a coin in the flaunch ecosystem that reinvests trading revenue into the acquisition of Zupermat artworks.

The app is composed of 2 parts:

- A react dashboard app that display the revenue and the acquisitions
- A flaunch Revenue Manager contract that manages the tokens and the claimable revenue

The ethereum contracts should be testable using the foundry toolkit

### Claim and acquisition process

1. Compare revenue available to claim in revenue manager to the floor price of the NFT collection
2. If the available balance if larger than the floor price, claim the revenue, bridge the revenue from base to ethereum, acquire the floor NFT.

### Related docs

- Flaunch RevenueManager: https://docs.flaunch.gg/manager-types/revenuemanager
- Across docs for bridging context: https://docs.across.to/
