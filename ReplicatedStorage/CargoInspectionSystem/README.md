# Cargo inspection zones

Cargo inspection uses the existing `ZoneLoader` convention. Create a Folder in
Workspace, put one or more invisible zone Parts inside it, and configure the
Folder as follows:

- CollectionService tag: `ZoneFolder`
- `ZoneType` string attribute: `CargoInspection`
- `ZoneKey` string attribute: a globally unique zone key
- `InspectionId` string attribute: a stable, unique customs checkpoint ID
- `ScannerStrength` number attribute: `0` through `1` (default `0.8`)
- `ScanDelay` number attribute: seconds (default `1.5`)
- `EnforcementPolicy` string attribute: `Civilian`, `Corporate`, or `Military` (default `Civilian`)
- `Jurisdiction` string attribute: authority displayed to the player (default `Local Security`)
- `FineMultiplier` optional number attribute: overrides the offense-class fine (`0` disables the fine)
- Optional descendant `HoldingCellGroup` ObjectValue: set `Value` to a Folder/Model containing jail cells
- Each direct child cell needs a descendant `HoldingPoint` Attachment/BasePart and a `HoldingDoor` ObjectValue whose `Value` is that cell's laser-door model
- Legacy single-cell setup: a descendant `HoldingPoint` and `HoldingDoor` directly beneath the inspection source remain supported
- Optional `CustodyDuration` number attribute: sentence length in seconds (default `180`)

Enforcement matrix:

| Policy | Restricted | Illegal | Capital |
| --- | --- | --- | --- |
| Civilian | Fine | Arrest | Arrest |
| Corporate | Fine | Arrest | Lethal |
| Military | Arrest | Arrest | Lethal |

Default fines are 50%, 100%, and 200% of the advertised payout for Restricted,
Illegal, and Capital cargo respectively. They never reduce credits below zero.

The zone automatically tracks only active contraband delivery cargo. It handles
cargo being carried, dropped, or mounted on a ship. A checkpoint rolls only once
per cargo contract, even if the cargo leaves and re-enters it.

An optional descendant Sound named `Alarm` plays when contraband is detected.
Existing tagged body scanners also detect contraband cargo currently carried by
the player.

Arrest and lethal outcomes fire the server-side BindableEvent at
`ServerScriptService.CargoInspectionSystem.EnforcementRequested`. Its payload
contains `player`, `cargo`, `cargoName`, `jobKey`, `inspectionId`,
`offenseClass`, `policy`, `response`, and `jurisdiction`.
The `SecurityResponseSystem` consumes this event to create the timed player
incident and HUD. A future guard adapter should subscribe to
`ServerScriptService.SecurityResponseSystem.IncidentChanged`; the inspection
system deliberately does not make unrelated enemy NPCs behave like guards.
