# PlayerMeterSystem

Server-authoritative player meters are declared in
`ReplicatedStorage.PlayerMeterSystem.Config`. Current and maximum values are
replicated as Player attributes, allowing HUDs to update without a dedicated
remote for each meter.

`PlayerMeterService` supports direct `Get`, `Set`, and `Add` operations plus
named rate sources. Rate sources compose additively and are removed by key, so
several effects can influence the same meter without overwriting each other.

Biohazard is the first meter. It ranges from 0 to 100, recovers slowly by
default, and gains exposure while the Stink effect is active.
