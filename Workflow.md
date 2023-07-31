## What we want it to do?

1. Users can enter by paying for a ticket.
    1. The ticket fees are going to go to the winner during the draw.
2. After X period of time, the lottery will automatically draw a winner
    1. And this will be done programatically.
3. Using Chainlink VRF & Chainlink Automation
    1. Chainlink VRF -> Randomness
    2. Chainlink Automation -> Time based trigger

## Tests!

1. Write some deploy scripts
2. Write our tests
    1. Work on local chain
    2. Forked Testnet
    3. Forked Mainnet

To run test on forked testnet

```
$ forge test --fork-url $SEPOLIA_RPC_URL
```

## Create Subscription

To create subscription
https://vrf.chain.link
current subId = 3294

This subscription will be funded through script.
If there is no SubId, then subscription id will be created and funded through script.

## Add Consumer

To add consumer
https://automation.chain.link
use the custom logic

Fund the consumer using link tokens
