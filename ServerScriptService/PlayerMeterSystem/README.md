# PlayerMeterSystem

Server-authoritative player meters are declared in
`ReplicatedStorage.PlayerMeterSystem.Config`. Current and maximum values are
replicated as Player attributes, allowing HUDs to update without a dedicated
remote for each meter.

`PlayerMeterService` supports direct `Get`, `Set`, and `Add` operations plus
named rate sources. Rate sources compose additively and are removed by key, so
several effects can influence the same meter without overwriting each other.

Biohazard is the first meter. It ranges from 0 to 100, recovers slowly by
default, and gains exposure while effects or hazardous cargo add named rate
sources. At 80 biohazard it begins damaging health at 2 health per second; the
damage ramps to 12 health per second at 100 biohazard. Biohazard resets on
respawn. Damage is routed through the shared `PlayerHit` event so custom player
health, HUD updates, and the normal death lifecycle remain authoritative.

Protective equipment can set the Player attribute `BiohazardProtection` from
0 (no protection) to 1 (complete protection). This reduces incoming positive
exposure without slowing natural recovery. The attribute is a hook for the
equipment system; no protection item is equipped automatically by this system.
