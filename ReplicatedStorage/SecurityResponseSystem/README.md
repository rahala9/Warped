# Security response incidents

`SecurityResponseService` consumes non-fine cargo enforcement requests and
creates one server-authoritative incident per player. A Lethal incident cannot
be downgraded by a later Arrest request; equal or higher reports refresh it.

Default durations:

- Arrest: 120 seconds
- Lethal: 180 seconds

The player receives replicated attributes for other server/client systems:

- `SecurityResponse`
- `SecurityJurisdiction`
- `SecurityOffenseClass`
- `SecurityIncidentExpiresAt`

The HUD displays the response, jurisdiction, offense, and remaining time.
Incidents clear on expiration, player death, or successful surrender.
New enforcement reports are rejected while the player is dead, preventing a
delayed inspection result from recreating an incident after death. Character
removal and respawn also clear incidents as defensive lifecycle boundaries.

## Surrender

Add an ObjectValue named `HoldingCellGroup` beneath a cargo inspection zone or
body-scanner model and set its `Value` to the Folder/Model containing that
jurisdiction's cells. Each direct child cell must contain a `HoldingPoint`
Attachment/BasePart and a `HoldingDoor` ObjectValue pointing to its laser door.
At arrest time, the server randomly reserves an available cell and records its
occupant. A cell cannot receive another prisoner until custody ends and, for a
timed release, its door has closed again. The older single `HoldingPoint` plus
`HoldingDoor` layout remains supported as a fallback.

Custody lasts 180 seconds by default and has its own visible release countdown.
At release, the selected cell's laser door is disabled for 30 seconds and then
safely re-enabled. A `CustodyDuration` number attribute on
the inspection source overrides the sentence length. Future escape routes can
call `SecurityResponseService:ReleaseCustody(player, reason, false)` through
their server-side handler without duplicating custody state.

## Guard integration

`SecurityGuardService` subscribes server-side to
`ServerScriptService.SecurityResponseSystem.IncidentChanged`. It dispatches
only NPC models tagged `SecurityGuard` whose `SecurityJurisdiction` attribute
matches the incident jurisdiction.

- `Arrest` guards pursue without attacking. At close range, they move the
  player to the inspection area's `HoldingPoint` and clear the incident.
- `Lethal` guards pursue and use their normal enemy combat behavior.
- Assignments clear when the incident clears, expires, or the player dies.
- Guards beyond `GuardDispatchRadius` are not dispatched.

The `ZAP09FSpawn1` entry in `EnemySpawningConfig` is the initial implementation:
spawned `ZAP-09-F` models receive the `SecurityGuard` tag and the
`SecurityJurisdiction = "Station Customs"` attribute. Other guard spawners can
opt in with the same `AdditionalTags` and `ModelAttributes` fields.
