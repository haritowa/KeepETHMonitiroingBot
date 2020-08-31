> **Bot link: [@KeepBoundingAlertsBot](https://t.me/KeepBoundingAlertsBot)**

## Previous PFK
For the last PFK, our team developed a telegram bot for monitoring available for stacking ETH(with alerts about low available ETH). For some reason, it was ignored during the judgment, so I decide to reiterate our achievements during previous PFK before describing updates.

[Our bot](https://t.me/KeepBoundingAlertsBot) checks available for stacking ETH hourly and sends corresponding alerts is available ETH falls below specified by user level. We choose this strategy to save infura API calls, which allows us to monitor up to *4150* operators without any additional setup from our users. Our goal is to create a robust, fault-tolerant solution, which may someday become a must-have tool for stackers. Source code is available in [this repo](https://github.com/haritowa/KeepETHMonitiroingBot)

While self-hosting is not required, we provide a docker-compose file(DB, Server, NGINX) so that anybody may run this bot with ease.

## Current PFK
During the current PFK, we developed a new feature: **Courtesy Call alerts**. Unfortunately, there are zero real cases of undercollateralization, so currently, this feature only works in theory. So I decide to describe this mechanism in detail:
1. Each hour our bot reads `CourtesyCall` events from `TBTCSystem` Contract
2. It filters events with timestamp 6+ hours ago
3. Using `collateralizationPercentage`, `undercollateralizedThresholdPercent` and `severelyUndercollateralizedThresholdPercent` of `Deposit` Contract it calculates collateralization level for each deposit
4. Using `keepAddress` (`Deposit` contract) and `members` (`BondedECDSAKeep` Contract), it fetches all stackers for this deposit
5. Finally, it matches an operator address with DB and sends appropriate alerts

You can study this functionality closer via this [pull request](https://github.com/haritowa/KeepETHMonitiroingBot/pull/16)


## Next PFK
During the next PFK, we have plans to:
* cover both alerts with tests(using ganache) to eliminate all “unpleasant surprises” even without real data
* update bot “UI” if users decide that the current version is counterintuitive
* add monitoring tool(Sentry)
* and to develop keep slashing alerts
